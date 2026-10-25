package br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import org.springframework.http.HttpStatus;

import java.lang.reflect.*;
import java.util.*;

public final class ConversorObjetos {

    private static final String PACOTE_BASE = "br.com.jhoneferreiradev.iconfeitto";

    private ConversorObjetos() {
    }

    // ---------- converter ----------

    public static <T> T converter(Object origem, Class<?> classeEntrada, Class<T> classeSaida) {
        if (origem == null) return null;

        try {
            if (classeSaida.isRecord()) {
                return converterParaRecord(origem, classeEntrada, classeSaida);
            }

            T destino = classeSaida.getDeclaredConstructor().newInstance();

            for (Field campoDestino : camposDe(classeSaida)) {
                Field campoOrigem = buscarCampo(classeEntrada, campoDestino.getName());
                if (campoOrigem == null) continue;

                campoOrigem.setAccessible(true);
                campoDestino.setAccessible(true);

                Object valor = campoOrigem.get(origem);
                campoDestino.set(destino,
                        converterValor(valor, campoDestino.getGenericType(), campoDestino.getType()));
            }
            return destino;

        } catch (ReflectiveOperationException e) {
            throw new IConfeittoException(
                    "Erro ao converter " + classeEntrada.getName() + " para " + classeSaida.getName(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // Records são imutáveis: monta os valores de cada componente e chama o construtor canônico
    private static <T> T converterParaRecord(Object origem, Class<?> classeEntrada, Class<T> classeSaida)
            throws ReflectiveOperationException {

        RecordComponent[] componentes = classeSaida.getRecordComponents();
        Class<?>[] tipos = new Class<?>[componentes.length];
        Object[] valores = new Object[componentes.length];

        for (int i = 0; i < componentes.length; i++) {
            RecordComponent componente = componentes[i];
            Class<?> tipo = componente.getType();
            tipos[i] = tipo;

            Object valor = null;
            Field campoOrigem = buscarCampo(classeEntrada, componente.getName());
            if (campoOrigem != null) {
                campoOrigem.setAccessible(true);
                valor = converterValor(campoOrigem.get(origem), componente.getGenericType(), tipo);
            }

            // construtor canônico não aceita null em tipo primitivo
            if (valor == null && tipo.isPrimitive()) {
                valor = valorPadraoPrimitivo(tipo);
            }
            valores[i] = valor;
        }

        Constructor<T> construtor = classeSaida.getDeclaredConstructor(tipos);
        construtor.setAccessible(true);
        return construtor.newInstance(valores);
    }

    private static Object valorPadraoPrimitivo(Class<?> tipo) {
        return Array.get(Array.newInstance(tipo, 1), 0);
    }

    // ---------- atualizar ----------

    public static void atualizarIgnorandoNulos(Object objetoOrigem, Object objetoDestino) {
        atualizar(objetoOrigem, objetoDestino, true);
    }

    private static void atualizar(Object objetoOrigem, Object objetoDestino, boolean ignorarNulos) {
        if (objetoOrigem == null || objetoDestino == null) {
            throw new IConfeittoException(
                    "objetoOrigem e objetoDestino não podem ser nulos", HttpStatus.INTERNAL_SERVER_ERROR);
        }

        if (objetoDestino.getClass().isRecord()) {
            throw new IConfeittoException(
                    "Não é possível atualizar um record (imutável): " + objetoDestino.getClass().getName(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }

        try {
            for (Field campoOrigem : camposDeLeitura(objetoOrigem.getClass())) {
                Field campoDestino = buscarCampo(objetoDestino.getClass(), campoOrigem.getName());
                if (campoDestino == null) continue;

                campoOrigem.setAccessible(true);
                campoDestino.setAccessible(true);

                Object valor = campoOrigem.get(objetoOrigem);
                if (valor == null && ignorarNulos) continue;

                Object valorConvertido = converterValor(valor, campoDestino.getGenericType(), campoDestino.getType());
                Object valorAtualDestino = campoDestino.get(objetoDestino);
                campoDestino.set(objetoDestino, copiarValor(valorConvertido, valorAtualDestino));
            }
        } catch (IllegalAccessException e) {
            throw new IConfeittoException(
                    "Erro ao atualizar " + objetoDestino.getClass().getName(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private static Object copiarValor(Object valor, Object valorAtualDestino) {
        if (!(valor instanceof Collection<?> origem)) return valor;

        if (valorAtualDestino instanceof Collection<?> existente) {
            if (existente == origem) return existente;

            try {
                Collection<Object> destino = (Collection<Object>) existente;
                destino.clear();
                destino.addAll(origem);
                return destino;
            } catch (UnsupportedOperationException e) {
                // coleção imutável: cai para a criação de uma nova
            }
        }

        return origem instanceof Set<?>
                ? new LinkedHashSet<>(origem)
                : new ArrayList<>(origem);
    }

    // ---------- conversão de valores ----------

    private static Object converterValor(Object valor, Type tipoGenericoDestino, Class<?> tipoDestino) {
        if (valor == null) return null;

        // 1) Lista / Set: converte cada elemento
        if (valor instanceof Collection<?> colecao) {
            return converterColecao(colecao, tipoGenericoDestino, tipoDestino);
        }

        // 2) Objeto do seu pacote: converte recursivamente
        if (ehDoPacote(valor.getClass()) && ehDoPacote(tipoDestino)) {
            if (valor.getClass().isEnum() && tipoDestino.isEnum()) {
                return converterEnum(valor, tipoDestino);
            }
            return converter(valor, valor.getClass(), tipoDestino);
        }

        // 3) Tipos simples (String, Long, LocalDate, etc.): copia direto
        return valor;
    }

    private static Collection<Object> converterColecao(Collection<?> origem, Type tipoGenericoDestino, Class<?> tipoDestino) {
        Collection<Object> resultado = Set.class.isAssignableFrom(tipoDestino)
                ? new LinkedHashSet<>()
                : new ArrayList<>();

        Class<?> tipoElementoDestino = tipoDoElemento(tipoGenericoDestino);

        for (Object elemento : origem) {
            if (elemento != null
                    && tipoElementoDestino != null
                    && ehDoPacote(elemento.getClass())
                    && ehDoPacote(tipoElementoDestino)) {
                resultado.add(converter(elemento, elemento.getClass(), tipoElementoDestino));
            } else {
                resultado.add(elemento);
            }
        }
        return resultado;
    }

    // ---------- auxiliares ----------

    private static Class<?> tipoDoElemento(Type tipo) {
        if (tipo instanceof ParameterizedType pt) {
            Type arg = pt.getActualTypeArguments()[0];
            if (arg instanceof Class<?> c) return c;
        }
        return null;
    }

    private static Object converterEnum(Object valor, Class<?> enumDestino) {
        return Enum.valueOf((Class<Enum>) enumDestino, ((Enum<?>) valor).name());
    }

    private static boolean ehDoPacote(Class<?> classe) {
        return classe.getPackageName().startsWith(PACOTE_BASE);
    }

    // Campos que podem ser GRAVADOS (destino): não static e não final
    private static List<Field> camposDe(Class<?> classe) {
        List<Field> campos = new ArrayList<>();
        for (Class<?> c = classe; c != null && c != Object.class; c = c.getSuperclass()) {
            for (Field f : c.getDeclaredFields()) {
                if (!Modifier.isStatic(f.getModifiers()) && !Modifier.isFinal(f.getModifiers())) {
                    campos.add(f);
                }
            }
        }
        return campos;
    }

    // Campos que podem ser LIDOS (origem): se for record, inclui os final
    private static List<Field> camposDeLeitura(Class<?> classe) {
        if (!classe.isRecord()) return camposDe(classe);

        List<Field> campos = new ArrayList<>();
        for (Field f : classe.getDeclaredFields()) {
            if (!Modifier.isStatic(f.getModifiers())) {
                campos.add(f);
            }
        }
        return campos;
    }

    private static Field buscarCampo(Class<?> classe, String nome) {
        for (Class<?> c = classe; c != null && c != Object.class; c = c.getSuperclass()) {
            try {
                return c.getDeclaredField(nome);
            } catch (NoSuchFieldException ignorado) {
            }
        }
        return null;
    }

}
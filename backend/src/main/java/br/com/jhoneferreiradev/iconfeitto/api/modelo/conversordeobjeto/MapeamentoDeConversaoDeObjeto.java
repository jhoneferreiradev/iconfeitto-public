package br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import org.springframework.http.HttpStatus;

import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;

public class MapeamentoDeConversaoDeObjeto {

    private final Map<Class<?>, Class<?>> mapaDeClasses = new ConcurrentHashMap<>();

    /**
     * Registra que objetos de "entrada" são convertidos para "saida" (1 para 1).
     */
    public MapeamentoDeConversaoDeObjeto registrar(Class<?> entrada, Class<?> saida) {
        Objects.requireNonNull(entrada, "entrada não pode ser nula");
        Objects.requireNonNull(saida, "saida não pode ser nula");

        Class<?> existente = mapaDeClasses.putIfAbsent(entrada, saida);
        if (existente != null && !existente.equals(saida)) {
            throw new IConfeittoException(
                    entrada.getName() + " já está registrada para " + existente.getName()
                            + " e não pode ser registrada também para " + saida.getName(), HttpStatus.INTERNAL_SERVER_ERROR);
        }

        return this;
    }

    /**
     * Devolve a classe de saída registrada para a classe de entrada.
     * A busca sobe pelas superclasses da entrada.
     *
     * @param entrada       classe do valor de origem
     * @param tipoDeclarado tipo declarado no destino (campo/componente); pode ser null
     * @return a saída registrada; se não houver registro (ou ela não couber no tipo
     * declarado), devolve o próprio tipoDeclarado
     */
    public Class<?> resolver(Class<?> entrada, Class<?> tipoDeclarado) {
        for (Class<?> c = entrada; c != null && c != Object.class; c = c.getSuperclass()) {
            Class<?> saida = mapaDeClasses.get(c);
            if (saida == null) continue;

            if (tipoDeclarado == null || tipoDeclarado.isAssignableFrom(saida)) {
                return saida;
            }
            return tipoDeclarado;
        }
        return tipoDeclarado;
    }
}

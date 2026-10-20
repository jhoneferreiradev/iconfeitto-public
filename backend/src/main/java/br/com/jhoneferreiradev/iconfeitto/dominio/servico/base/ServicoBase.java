package br.com.jhoneferreiradev.iconfeitto.dominio.servico.base;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Optional;

public interface ServicoBase<T> {
    T salvar(T object);

    Optional<T> buscarPorId(Long id);

    List<T> listarTodos();

    List<T> listarTodosAtivos();

    void remover(Long id);

    String getNomeObjeto();

    default T getPorId(Long id) {
        return buscarPorId(id).orElseThrow(this::construirIConfeittoExceptionObjetoNaoEncontrado);
    }

    default IConfeittoException construirIConfeittoExceptionObjetoNaoEncontrado() {
        return new IConfeittoException(String.format("%s não encontrado", getNomeObjeto()), HttpStatus.BAD_REQUEST);
    }
}

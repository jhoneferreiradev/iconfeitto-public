package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.validation.core;

public abstract class ValidavelBaseAoSalvar<T extends ValidavelAoSalvar> implements ValidadorDeSalvamento {

    @SuppressWarnings("unchecked")
    @Override
    public void validar(ValidavelAoSalvar validavelAoSalvar) {
        validarEntidade((T) validavelAoSalvar);
    }

    protected abstract void validarEntidade(T entity);
}
package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.validation.core;

public interface ValidavelAoSalvar {
    Class<? extends ValidavelBaseAoSalvar> getValidadorBase();
}

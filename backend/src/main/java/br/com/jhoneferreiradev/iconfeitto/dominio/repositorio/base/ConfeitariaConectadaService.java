package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;

import java.util.Optional;

public interface ConfeitariaConectadaService {
    Optional<Confeitaria> getConfeitariaConectada();
}

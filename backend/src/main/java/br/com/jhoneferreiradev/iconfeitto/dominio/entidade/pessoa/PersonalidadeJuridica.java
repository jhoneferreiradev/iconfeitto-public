package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa;

import lombok.Getter;
public enum PersonalidadeJuridica {
    PF("Física"),
    PJ("Jurídica");

    @Getter
    private final String descricao;

    PersonalidadeJuridica(String descricao) {
        this.descricao = descricao;
    }
}
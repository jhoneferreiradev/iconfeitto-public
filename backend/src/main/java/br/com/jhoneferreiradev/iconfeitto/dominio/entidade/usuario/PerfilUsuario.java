package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.usuario;

import lombok.Getter;

public enum PerfilUsuario {

    ADMINISTRADOR("Administrador");

    @Getter
    private final String descricao;

    PerfilUsuario(String descricao) {
        this.descricao = descricao;
    }
}
package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida;

import lombok.Getter;

public enum GrupoUnidadeMedida {
    PESO("Peso"),
    VOLUME("Volume"),
    UNIDADE("Unidade"),
    COMPRIMENTO("Comprimento");

    @Getter
    private String descricao;

    GrupoUnidadeMedida(String descricao) {
        this.descricao = descricao;
    }

}

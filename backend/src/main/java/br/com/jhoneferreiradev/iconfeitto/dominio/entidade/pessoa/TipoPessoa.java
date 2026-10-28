package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa;

import lombok.Getter;

public enum TipoPessoa {
    CLIENTE( "Cliente"),
    FORNECEDOR("Fornecedor"),
    CARTAO( "Cartão"),
    BANDEIRA_CARTAO( "Bandeira de Cartão");

    @Getter
    private final String descricao;

    TipoPessoa(String descricao) {
        this.descricao = descricao;
    }
}
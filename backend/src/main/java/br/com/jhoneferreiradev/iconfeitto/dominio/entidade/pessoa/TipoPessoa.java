package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa;

import lombok.Getter;

public enum TipoPessoa {
    CLIENTE("00", "Cliente"),
    FORNECEDOR("01", "Fornecedor"),
    CARTAO("02", "Cartão"),
    BANDEIRA_CARTAO("03", "Bandeira de Cartão");

    @Getter
    private final String id;

    @Getter
    private final String descricao;

    TipoPessoa(String id, String descricao) {
        this.id = id;
        this.descricao = descricao;
    }
}
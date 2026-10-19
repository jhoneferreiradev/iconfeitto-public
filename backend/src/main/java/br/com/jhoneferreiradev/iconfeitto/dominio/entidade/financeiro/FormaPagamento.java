package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro;

import lombok.Getter;

public enum FormaPagamento {
    DINHEIRO("Dinheiro"),
    CARTAO_CREDITO("Cartão de Crédito"),
    CARTAO_DEBITO("Cartão de Débito"),
    PIX("Pix");

    @Getter
    private final String descricao;

    FormaPagamento(String descricao) {
        this.descricao = descricao;
    }
}
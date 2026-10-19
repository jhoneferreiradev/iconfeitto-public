package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro;

import lombok.Getter;

public enum TipoLancamentoFinanceiro {
    A_RECEBER("A Receber"),
    A_PAGAR("A Pagar");

    @Getter
    private final String descricao;

    TipoLancamentoFinanceiro(String descricao) {
        this.descricao = descricao;
    }
}
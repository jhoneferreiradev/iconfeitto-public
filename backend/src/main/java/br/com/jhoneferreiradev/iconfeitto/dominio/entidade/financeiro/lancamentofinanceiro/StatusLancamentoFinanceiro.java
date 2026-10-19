package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro;

import lombok.Getter;

public enum StatusLancamentoFinanceiro {
    PENDENTE("Pendente"),
    QUITADO("Quitado");

    @Getter
    private final String descricao;

    StatusLancamentoFinanceiro(String descricao) {
        this.descricao = descricao;
    }
}
package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao;

import lombok.Getter;

public enum TipoTaxaBandeiraCartao {

    PERCENTUAL("Percentual"),
    VALOR_FIXO("Valor Fixo");

    @Getter
    private final String descricao;

    TipoTaxaBandeiraCartao(String descricao) {
        this.descricao = descricao;
    }

}

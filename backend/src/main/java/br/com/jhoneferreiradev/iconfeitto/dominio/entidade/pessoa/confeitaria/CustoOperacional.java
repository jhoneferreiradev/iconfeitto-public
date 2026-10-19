package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadeBaseComDadosPadraoComConfeitaria;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_custo_operacional")
@NoArgsConstructor
public class CustoOperacional extends EntidadeBaseComDadosPadraoComConfeitaria {

    @EqualsAndHashCode.Include
    private String nome;
    private BigDecimal valor;

    public CustoOperacional(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm,
                            String nome, BigDecimal valor) {
        super(id, confeitaria, criadoEm);
        this.nome = nome;
        this.valor = valor;
    }
}

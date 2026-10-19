package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadePadraoAtivavelComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_unidade_medida")
@NoArgsConstructor
public class UnidadeMedida extends EntidadePadraoAtivavelComConfeitaria {

    private String nome;
    @EqualsAndHashCode.Include
    private String sigla;
    @Enumerated(EnumType.STRING)
    private GrupoUnidadeMedida grupo;
    private BigDecimal fatorParaBase;


    public UnidadeMedida(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo,
                         String nome, String sigla, GrupoUnidadeMedida grupo, BigDecimal fatorParaBase) {
        super(id, confeitaria, criadoEm, ativo);
        this.nome = nome;
        this.sigla = sigla;
        this.grupo = grupo;
        this.fatorParaBase = fatorParaBase;
    }
}

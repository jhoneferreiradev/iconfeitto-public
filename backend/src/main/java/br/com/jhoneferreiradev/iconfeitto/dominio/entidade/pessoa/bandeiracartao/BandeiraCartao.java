package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.Pessoa;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.TipoPessoa;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_bandeira_cartao")
@DiscriminatorValue("03") // 03 = TipoPessoa.BANDEIRA_CARTAO.getId()
@PrimaryKeyJoinColumn(name = "id")
public class BandeiraCartao extends Pessoa {

    private BigDecimal taxa;
    private int diasCompensacao;
    @Enumerated(EnumType.STRING)
    private TipoTaxaBandeiraCartao tipoTaxa;

    public BandeiraCartao() {
        this.setPersonalidadeJuridica(PersonalidadeJuridica.PJ);
    }

    public BandeiraCartao(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo,
                          String nome, TipoPessoa tipoPessoa,
                          BigDecimal taxa, int diasCompensacao, TipoTaxaBandeiraCartao tipoTaxa) {
        super(id, confeitaria, criadoEm, ativo, PersonalidadeJuridica.PJ, nome, tipoPessoa);
        this.taxa = taxa;
        this.diasCompensacao = diasCompensacao;
        this.tipoTaxa = tipoTaxa;
    }
}

package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cartao;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.Pessoa;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.TipoPessoa;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_cartao")
@DiscriminatorValue("CARTAO") // 02 = TipoPessoa.CARTAO.getId()
@PrimaryKeyJoinColumn(name = "id")
public class Cartao extends Pessoa {

    private int diaVencimento;
    private int diasParaFechamento;

    public Cartao() {
        this.setPersonalidadeJuridica(PersonalidadeJuridica.PJ);
    }

    public Cartao(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo,
                  String nome, TipoPessoa tipoPessoa,
                  int diaVencimento, int diasParaFechamento) {
        super(id, confeitaria, criadoEm, ativo, PersonalidadeJuridica.PJ, nome, tipoPessoa);
        this.diaVencimento = diaVencimento;
        this.diasParaFechamento = diasParaFechamento;
    }
}

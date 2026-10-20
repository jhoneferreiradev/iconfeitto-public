package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.Pessoa;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.TipoPessoa;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.PrimaryKeyJoinColumn;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Data
@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Entity
@Table(name = "tb_fornecedor")
@DiscriminatorValue("01") // 01 = TipoPessoa.FORNECEDOR.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class Fornecedor extends Pessoa {

    public Fornecedor(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo,
                      PersonalidadeJuridica personalidadeJuridica, String nome, TipoPessoa tipoPessoa) {
        super(id, confeitaria, criadoEm, ativo, personalidadeJuridica, nome, tipoPessoa);
    }
}

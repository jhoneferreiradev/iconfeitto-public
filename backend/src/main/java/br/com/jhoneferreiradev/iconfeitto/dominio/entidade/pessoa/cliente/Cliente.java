package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente;

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

@Data
@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Entity
@Table(name = "tb_cliente")
@DiscriminatorValue("CLIENTE") // 00 = TipoPessoa.CLIENTE.getId()
@PrimaryKeyJoinColumn(name = "id")
public class Cliente extends Pessoa {

    public Cliente() {
        this.setPersonalidadeJuridica(PersonalidadeJuridica.PF);
    }

    public Cliente(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo, String nome, TipoPessoa tipoPessoa) {
        super(id, confeitaria, criadoEm, ativo, PersonalidadeJuridica.PF, nome, tipoPessoa);
    }

}

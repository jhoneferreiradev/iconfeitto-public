package br.com.jhoneferreiradev.iconfeitto.dominio.entidade;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Getter
@MappedSuperclass
@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@NoArgsConstructor
public abstract class EntidadePadraoAtivavelComConfeitaria extends EntidadeBaseComDadosPadraoComConfeitaria implements EntidadeComConfeitaria {

    @Column(name = "is_ativo")
    private boolean ativo = true;

    public EntidadePadraoAtivavelComConfeitaria(Long id, Confeitaria confeitaria,
                                                OffsetDateTime criadoEm, boolean ativo) {
        super(id, confeitaria, criadoEm);
        this.ativo = ativo;
    }
}
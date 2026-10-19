package br.com.jhoneferreiradev.iconfeitto.dominio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

import static java.util.Objects.isNull;

@Getter
@MappedSuperclass
@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@NoArgsConstructor
public abstract class EntidadeBaseComDadosPadraoComConfeitaria extends EntidadeBase implements EntidadeComConfeitaria {

    @Setter
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "confeitaria_id")
    private Confeitaria confeitaria;

    @Column(name = "criado_em", updatable = false)
    private OffsetDateTime criadoEm;

    public EntidadeBaseComDadosPadraoComConfeitaria(Long id, Confeitaria confeitaria,
                                                    OffsetDateTime criadoEm) {
        super(id);
        this.confeitaria = confeitaria;
        this.criadoEm = criadoEm;
    }

    @PrePersist
    protected void onCreate() {
        if (isNull(criadoEm)) {
            criadoEm = OffsetDateTime.now(ZoneOffset.ofHours(-3));
        }
    }
}
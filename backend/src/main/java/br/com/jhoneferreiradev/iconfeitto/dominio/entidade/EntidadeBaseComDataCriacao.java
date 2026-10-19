package br.com.jhoneferreiradev.iconfeitto.dominio.entidade;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

import static java.util.Objects.isNull;

@Getter
@MappedSuperclass
@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@NoArgsConstructor
public abstract class EntidadeBaseComDataCriacao extends EntidadeBase {

    @EqualsAndHashCode.Include
    @Column(name = "criado_em", updatable = false)
    private OffsetDateTime criadoEm;

    public EntidadeBaseComDataCriacao(Long id, OffsetDateTime criadoEm) {
        super(id);
        this.criadoEm = criadoEm;
    }

    @PrePersist
    protected void onCreate() {
        if (isNull(getCriadoEm())) {
            criadoEm = OffsetDateTime.now(ZoneOffset.ofHours(-3));
        }
    }
}
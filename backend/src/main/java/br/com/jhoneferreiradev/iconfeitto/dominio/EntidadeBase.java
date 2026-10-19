package br.com.jhoneferreiradev.iconfeitto.dominio;

import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import static java.util.Objects.nonNull;

@Data
@MappedSuperclass
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor
public abstract class EntidadeBase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    public EntidadeBase(Long id) {
        this.id = id;
    }

    public boolean salvo() {
        return nonNull(id);
    }

    public boolean naoSalvo() {
        return !salvo();
    }

}
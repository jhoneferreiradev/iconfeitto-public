package br.com.jhoneferreiradev.iconfeitto.dominio.excecao.modelo;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import org.springframework.http.HttpStatus;
import org.springframework.validation.FieldError;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;

@Schema(name = "IConfeittoErro", description = "Objeto de erro retornado pela API")
@Getter
@EqualsAndHashCode
public class IConfeittoErro {

    @Schema(description = "Código HTTP do erro", example = "400")
    private final int code;

    @Schema(description = "Descrição do erro", example = "Recurso não encontrado")
    private final String description;

    @Schema(description = "Data e hora do erro (timezone -03:00)", example = "2026-09-07T16:41:11-03:00", type = "string", format = "date-time")
    private final OffsetDateTime dateTime = OffsetDateTime.now(ZoneOffset.ofHours(-3));

    public IConfeittoErro(IConfeittoException ex) {
        this.code = ex.getHttpStatusCodeException().value();
        this.description = ex.getMessage();
    }

    public IConfeittoErro(int code, String description) {
        this.code = code;
        this.description = description;
    }

    public IConfeittoErro(FieldError fieldError) {
        this(HttpStatus.BAD_REQUEST.value(),
                fieldError.getDefaultMessage());
    }
}

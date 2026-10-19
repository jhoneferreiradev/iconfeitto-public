package br.com.jhoneferreiradev.iconfeitto.api.config;

import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.modelo.IConfeittoErro;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import static org.springframework.http.ResponseEntity.status;

@Slf4j
@ControllerAdvice
public class IConfeittoExceptionHandler {


    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<IConfeittoErro> handle(RuntimeException ex) {

        if (ex instanceof IConfeittoException) {
            return status(((IConfeittoException) ex)
                    .getHttpStatusCodeException())
                    .body(new IConfeittoErro((IConfeittoException) ex));
        }

        if (ex instanceof HttpMessageNotReadableException) {
            return status(HttpStatus.BAD_REQUEST)
                    .body(new IConfeittoErro(HttpStatus.BAD_REQUEST.value(), ex.getMessage()));
        }

        log.error("Falha interna (RuntimeException.class): {}", ex.getMessage(), ex);

        return ResponseEntity
                .internalServerError()
                .body(getDefaultIConfeittoInternalError());

    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<IConfeittoErro> handle(MethodArgumentNotValidException ex) {
        return ResponseEntity
                .badRequest()
                .body(ex.getFieldErrors()
                        .stream()
                        .findFirst()
                        .map(IConfeittoErro::new)
                        .orElse(getDefaultIConfeittoInternalError()));
    }

    private IConfeittoErro getDefaultIConfeittoInternalError() {
        return new IConfeittoErro(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Falha interna");
    }

}

package br.com.jhoneferreiradev.iconfeitto.dominio.excecao;

import lombok.Getter;
import org.springframework.http.HttpStatusCode;

public class IConfeittoException extends RuntimeException {

    @Getter
    private HttpStatusCode httpStatusCodeException;

    public IConfeittoException(String message, HttpStatusCode httpStatusCodeException) {
        super(message);
        this.httpStatusCodeException = httpStatusCodeException;
    }
}

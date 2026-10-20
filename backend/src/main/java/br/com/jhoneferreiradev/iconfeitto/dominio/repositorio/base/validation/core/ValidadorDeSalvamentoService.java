package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.validation.core;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class ValidadorDeSalvamentoService {

    private final ApplicationContext applicationContext;

    @Autowired
    public ValidadorDeSalvamentoService(ApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    public void valid(ValidavelAoSalvar validavelAoSalvar) {
        Class<? extends ValidavelBaseAoSalvar> validadorBase = validavelAoSalvar.getValidadorBase();
        Map<String, ? extends ValidavelBaseAoSalvar> validadores = applicationContext.getBeansOfType(validadorBase);

        for (ValidavelBaseAoSalvar validador : validadores.values()) {
            validador.validar(validavelAoSalvar);
        }
    }
}
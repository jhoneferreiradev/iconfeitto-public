package br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.custooperacional;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Schema(
        name = "CustoOperacionalDTOSaida",
        description = "Dados de um custo operacional")
@NoArgsConstructor
@AllArgsConstructor
@Getter
public class CustoOperacionalDTOSaida {
    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "ID único do custo operacional",
            example = "42")
    private Long id;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Nome do custo operacional",
            example = "Energia elétrica")
    private String nome;

    @Schema(
            requiredMode = Schema.RequiredMode.REQUIRED,
            description = "Valor do custo operacional",
            example = "350.00")
    private BigDecimal valor;
}

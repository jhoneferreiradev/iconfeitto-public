package br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.estoque;

import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.GrupoUnidadeMedida;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

@Schema(
        name = "UnidadeMedidaDTOEntrada",
        description = "Dados para a criação ou atualização de uma unidade de medida. " +
                "Na atualização, atributos nulos ou não informados serão ignorados e não sobrescreverão os valores existentes")
public record UnidadeMedidaDTOEntrada(
        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Nome da unidade de medida. Obrigatório na criação",
                example = "Quilograma")
        @NotBlank(groups = ValidacaoInclusao.class)
        String nome,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Sigla da unidade de medida. Obrigatório na criação",
                example = "kg")
        @NotBlank(groups = ValidacaoInclusao.class)
        String sigla,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Grupo ao qual a unidade de medida pertence. Obrigatório na criação")
        @NotNull(groups = ValidacaoInclusao.class)
        GrupoUnidadeMedida grupo,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Fator de conversão desta unidade para a unidade base do grupo. Obrigatório na criação",
                example = "1000")
        @NotNull(groups = ValidacaoInclusao.class)
        BigDecimal fatorParaBase,

        @Schema(
                requiredMode = Schema.RequiredMode.NOT_REQUIRED,
                description = "Indica se a unidade de medida está ativa",
                example = "true")
        Boolean ativo
) {
}

package br.com.jhoneferreiradev.iconfeitto.api.controller;

import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.base.ServicoBase;
import lombok.AccessLevel;
import lombok.Getter;
import org.springframework.http.ResponseEntity;

import java.util.List;

public abstract class ControllerBase<ENTIDADE_BASE, DTO_SAIDA, DTO_ENTRADA> {

    @Getter(AccessLevel.PROTECTED)
    private ServicoBase<ENTIDADE_BASE> servicoBase;
    private Class<ENTIDADE_BASE> classEntidadeBase;
    private Class<DTO_SAIDA> classSaida;

    public ControllerBase(ServicoBase<ENTIDADE_BASE> servicoBase,
                          Class<ENTIDADE_BASE> classEntidadeBase,
                          Class<DTO_SAIDA> classSaida) {
        this.servicoBase = servicoBase;
        this.classEntidadeBase = classEntidadeBase;
        this.classSaida = classSaida;
    }

    public ResponseEntity<DTO_SAIDA> adicionar(DTO_ENTRADA dto) {
        ENTIDADE_BASE entidade = ConversorObjetos.converter(dto, dto.getClass(), classEntidadeBase);
        ENTIDADE_BASE entidadeSalva = servicoBase.salvar(entidade);
        DTO_SAIDA saida = ConversorObjetos.converter(entidadeSalva, classEntidadeBase, classSaida);
        return ResponseEntity.ok(saida);
    }

    public ResponseEntity<List<DTO_SAIDA>> listar() {
        List<ENTIDADE_BASE> entidades = servicoBase.listarTodos();
        List<DTO_SAIDA> saidas = entidades.stream().map(entidade -> ConversorObjetos.converter(entidade, classEntidadeBase, classSaida)).toList();
        return ResponseEntity.ok(saidas);
    }

    public ResponseEntity<DTO_SAIDA> buscarPorId(Long id) {
        ENTIDADE_BASE entidade = servicoBase.getPorId(id);
        DTO_SAIDA saida = ConversorObjetos.converter(entidade, classEntidadeBase, classSaida);
        return ResponseEntity.ok(saida);
    }

    public ResponseEntity<DTO_SAIDA> atualizar(Long id, DTO_ENTRADA dto) {
        ENTIDADE_BASE entidadeExistente = servicoBase.getPorId(id);
        ConversorObjetos.atualizarIgnorandoNulos(dto, entidadeExistente);
        ENTIDADE_BASE entidadeAtualizada = servicoBase.salvar(entidadeExistente);
        DTO_SAIDA saida = ConversorObjetos.converter(entidadeAtualizada, classEntidadeBase, classSaida);
        return ResponseEntity.ok(saida);
    }

}

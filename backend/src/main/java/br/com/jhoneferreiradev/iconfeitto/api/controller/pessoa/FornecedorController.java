package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.FornecedorControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.FornecedorDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.FornecedorDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor.Fornecedor;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.FornecedorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/fornecedores")
public class FornecedorController implements FornecedorControllerDoc {

    @Autowired
    private FornecedorService fornecedorService;

    @Transactional
    @PostMapping
    public ResponseEntity<FornecedorDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) FornecedorDTOEntrada dtoNovaFornecedor) {
        Fornecedor fornecedor = ConversorObjetos.converter(dtoNovaFornecedor, FornecedorDTOEntrada.class, Fornecedor.class);
        fornecedor = fornecedorService.salvar(fornecedor);
        FornecedorDTOSaida saida = ConversorObjetos.converter(fornecedor, Fornecedor.class, FornecedorDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<FornecedorDTOSaida>> listar() {
        List<Fornecedor> fornecedores = fornecedorService.listarTodos();
        List<FornecedorDTOSaida> saidas = fornecedores.stream().map(fornecedor -> ConversorObjetos.converter(fornecedor, Fornecedor.class, FornecedorDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<FornecedorDTOSaida> buscarPorId(@PathVariable Long id) {
        Fornecedor fornecedor = fornecedorService.getPorId(id);
        FornecedorDTOSaida saida = ConversorObjetos.converter(fornecedor, Fornecedor.class, FornecedorDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<FornecedorDTOSaida> atualizar(@PathVariable Long id, @RequestBody FornecedorDTOEntrada dtoAtualizacao) {
        Fornecedor fornecedorExistente = fornecedorService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, fornecedorExistente);

        Fornecedor fornecedorAtualizada = fornecedorService.salvar(fornecedorExistente);
        FornecedorDTOSaida saida = ConversorObjetos.converter(fornecedorAtualizada, Fornecedor.class, FornecedorDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}

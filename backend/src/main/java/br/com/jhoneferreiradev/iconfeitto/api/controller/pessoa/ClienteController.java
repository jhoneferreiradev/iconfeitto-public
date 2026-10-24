package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.ClienteControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.ClienteDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.ClienteDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente.Cliente;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.ClienteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/clientes")
public class ClienteController implements ClienteControllerDoc {

    @Autowired
    private ClienteService clienteService;

    @Transactional
    @PostMapping
    public ResponseEntity<ClienteDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) ClienteDTOEntrada dtoNovaCliente) {
        Cliente cliente = ConversorObjetos.converter(dtoNovaCliente, ClienteDTOEntrada.class, Cliente.class);
        cliente = clienteService.salvar(cliente);
        ClienteDTOSaida saida = ConversorObjetos.converter(cliente, Cliente.class, ClienteDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<ClienteDTOSaida>> listar() {
        List<Cliente> clientes = clienteService.listarTodos();
        List<ClienteDTOSaida> saidas = clientes.stream().map(cliente -> ConversorObjetos.converter(cliente, Cliente.class, ClienteDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClienteDTOSaida> buscarPorId(@PathVariable Long id) {
        Cliente cliente = clienteService.getPorId(id);
        ClienteDTOSaida saida = ConversorObjetos.converter(cliente, Cliente.class, ClienteDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<ClienteDTOSaida> atualizar(@PathVariable Long id, @RequestBody ClienteDTOEntrada dtoAtualizacao) {
        Cliente clienteExistente = clienteService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, clienteExistente);

        Cliente clienteAtualizada = clienteService.salvar(clienteExistente);
        ClienteDTOSaida saida = ConversorObjetos.converter(clienteAtualizada, Cliente.class, ClienteDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}

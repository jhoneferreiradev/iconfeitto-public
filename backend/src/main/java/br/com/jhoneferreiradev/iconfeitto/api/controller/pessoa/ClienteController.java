package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.ClienteControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
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
public class ClienteController
        extends ControllerBase<Cliente, ClienteDTOSaida, ClienteDTOEntrada>
        implements ClienteControllerDoc {

    @Autowired
    public ClienteController(ClienteService clienteService) {
        super(clienteService, Cliente.class, ClienteDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<ClienteDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) ClienteDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<ClienteDTOSaida>> listar() {
       return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClienteDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<ClienteDTOSaida> atualizar(@PathVariable Long id, @RequestBody ClienteDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

}

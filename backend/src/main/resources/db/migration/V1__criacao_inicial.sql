use iconfeitto;

CREATE TABLE IF NOT EXISTS tb_confeitaria
(
    id                     BIGINT   NOT NULL AUTO_INCREMENT,
    criado_em              DATETIME NOT NULL,
    nome                   VARCHAR(255) NULL,
    personalidade_juridica VARCHAR(10) NULL,
    documento              VARCHAR(25) NULL,
    endereco               VARCHAR(255) NULL,
    telefone               VARCHAR(30) NULL,
    facebook               VARCHAR(255) NULL,
    instagram              VARCHAR(255) NULL,
    PRIMARY KEY (id)
    );

CREATE TABLE IF NOT EXISTS tb_usuario
(
    id             BIGINT       NOT NULL AUTO_INCREMENT,
    confeitaria_id BIGINT       NOT NULL,
    criado_em      DATETIME     NOT NULL,
    is_ativo       BIT(1)       NOT NULL,
    nome           VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    perfil         VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_USUARIO_CONFEITARIA
    FOREIGN KEY (confeitaria_id) REFERENCES tb_confeitaria (id)
    );

CREATE TABLE IF NOT EXISTS tb_custo_operacional
(
    id             BIGINT         NOT NULL AUTO_INCREMENT,
    confeitaria_id BIGINT         NOT NULL,
    criado_em      DATETIME       NOT NULL,
    nome           VARCHAR(255)   NOT NULL,
    valor          DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_CUSTO_OPERACIONAL_CONFEITARIA
    FOREIGN KEY (confeitaria_id) REFERENCES tb_confeitaria (id)
    );

CREATE TABLE IF NOT EXISTS tb_unidade_medida
(
    id              BIGINT         NOT NULL AUTO_INCREMENT,
    confeitaria_id  BIGINT         NOT NULL,
    criado_em       DATETIME       NOT NULL,
    is_ativo        BIT(1)         NOT NULL,
    nome            VARCHAR(100)   NOT NULL,
    sigla           VARCHAR(20)    NOT NULL,
    grupo           VARCHAR(30)    NOT NULL,
    fator_para_base DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id)
    );

CREATE TABLE IF NOT EXISTS tb_pessoa
(
    id                     BIGINT       NOT NULL AUTO_INCREMENT,
    confeitaria_id         BIGINT       NOT NULL,
    criado_em              DATETIME     NOT NULL,
    is_ativo               BIT(1)       NOT NULL,
    nome                   VARCHAR(100) NOT NULL,
    personalidade_juridica VARCHAR(2)   NOT NULL,
    tipo_pessoa            VARCHAR(2)   NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_PESSOA_CONFEITARIA
    FOREIGN KEY (confeitaria_id) REFERENCES tb_confeitaria (id)
    );

CREATE TABLE IF NOT EXISTS tb_fornecedor
(
    id BIGINT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (id),
    CONSTRAINT FK_FORNECEDOR_PESSOA
    FOREIGN KEY (id) REFERENCES tb_pessoa (id)
    );

CREATE TABLE IF NOT EXISTS tb_cliente
(
    id BIGINT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (id),
    CONSTRAINT FK_CLIENTE_PESSOA
    FOREIGN KEY (id) REFERENCES tb_pessoa (id)
    );


CREATE TABLE IF NOT EXISTS tb_cartao
(
    id              BIGINT NOT NULL AUTO_INCREMENT,
    dia_vencimento  INT    NOT NULL,
    dias_para_fechamento INT    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_CARTAO_PESSOA FOREIGN KEY (id) REFERENCES tb_pessoa (id)
    );

CREATE TABLE IF NOT EXISTS tb_bandeira_cartao
(
    id               BIGINT        NOT NULL AUTO_INCREMENT,
    taxa             DECIMAL(8, 4) NOT NULL,
    dias_compensacao INT           NOT NULL,
    tipo_taxa        VARCHAR(30)   NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_BANDEIRA_CARTAO_PESSOA FOREIGN KEY (id) REFERENCES tb_pessoa (id)
    );

CREATE TABLE IF NOT EXISTS tb_item
(
    id                        BIGINT         NOT NULL AUTO_INCREMENT,
    confeitaria_id            BIGINT         NOT NULL,
    criado_em                 DATETIME       NOT NULL,
    is_ativo                  BIT(1)         NOT NULL,
    nome                      VARCHAR(100)   NOT NULL,
    tipo_item                 VARCHAR(30)    NOT NULL,

    unidade_medida_estoque_id BIGINT         NOT NULL,
    unidade_medida_consumo_id BIGINT         NOT NULL,
    saldo_estoque             DECIMAL(10, 2) NOT NULL,
    quantidade_minima_estoque DECIMAL(10, 2) NOT NULL,

    possui_ficha_tecnica      BIT(1)         NOT NULL,
    tempo_preparo_minutos     INT            NOT NULL,
    rendimento_receita        INT            NOT NULL,

    custo_medio               DECIMAL(10, 2) NOT NULL,
    custo_embalagem           DECIMAL(10, 2) NOT NULL,
    custo_operacional         DECIMAL(10, 2) NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT FK_ITEM_CONFEITARIA
    FOREIGN KEY (confeitaria_id) REFERENCES tb_confeitaria (id),
    CONSTRAINT FK_ITEM_UNIDADE_ESTOQUE
    FOREIGN KEY (unidade_medida_estoque_id) REFERENCES tb_unidade_medida (id),
    CONSTRAINT FK_ITEM_UNIDADE_CONSUMO
    FOREIGN KEY (unidade_medida_consumo_id) REFERENCES tb_unidade_medida (id)
    );

CREATE TABLE IF NOT EXISTS tb_item_ficha_tecnica
(
    id                 BIGINT         NOT NULL AUTO_INCREMENT,
    item_principal_id  BIGINT         NOT NULL,
    item_composicao_id BIGINT         NOT NULL,
    unidade_medida_id  BIGINT         NOT NULL,
    quantidade         DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_ITEM_FICHA_TECNICA_ITEM_PRINCIPAL
    FOREIGN KEY (item_principal_id) REFERENCES tb_item (id),
    CONSTRAINT FK_ITEM_FICHA_TECNICA_ITEM_COMPOSICAO
    FOREIGN KEY (item_composicao_id) REFERENCES tb_item (id),
    CONSTRAINT FK_ITEM_FICHA_TECNICA_UNIDADE_MEDIDA
    FOREIGN KEY (unidade_medida_id) REFERENCES tb_unidade_medida (id)
    );

CREATE TABLE IF NOT EXISTS tb_movimentacao_estoque
(
    id                BIGINT     NOT NULL AUTO_INCREMENT,
    confeitaria_id    BIGINT     NOT NULL,
    criado_em         DATETIME   NOT NULL,
    data              DATETIME   NOT NULL,
    tipo_movimentacao VARCHAR(2) NOT NULL,
    PRIMARY KEY (id)
    );

CREATE TABLE IF NOT EXISTS tb_item_movimentacao_estoque
(
    id                      BIGINT         NOT NULL AUTO_INCREMENT,
    movimentacao_estoque_id BIGINT         NOT NULL,
    item_id                 BIGINT         NOT NULL,
    unidade_medida_id       BIGINT         NOT NULL,
    quantidade              DECIMAL(10, 2) NOT NULL,
    valor_unitario          DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_ITEM_MOVIMENTACAO_ESTOQUE_MOVIMENTACAO
    FOREIGN KEY (movimentacao_estoque_id) REFERENCES tb_movimentacao_estoque (id),
    CONSTRAINT FK_ITEM_MOVIMENTACAO_ESTOQUE_ITEM
    FOREIGN KEY (item_id) REFERENCES tb_item (id),
    CONSTRAINT FK_ITEM_MOVIMENTACAO_ESTOQUE_UNIDADE_MEDIDA
    FOREIGN KEY (unidade_medida_id) REFERENCES tb_unidade_medida (id)
    );

CREATE TABLE IF NOT EXISTS tb_compra
(
    id            BIGINT NOT NULL AUTO_INCREMENT,
    fornecedor_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_COMPRA_FORNECEDOR
    FOREIGN KEY (fornecedor_id) REFERENCES tb_fornecedor (id),
    CONSTRAINT FK_COMPRA_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_venda
(
    id         BIGINT NOT NULL AUTO_INCREMENT,
    cliente_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_VENDA_CLIENTE
    FOREIGN KEY (cliente_id) REFERENCES tb_cliente (id),
    CONSTRAINT FK_VENDA_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_saida_consumo
(
    id BIGINT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (id),
    CONSTRAINT FK_CONSUMO_ESTOQUE_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_ajuste_saida
(
    id BIGINT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (id),
    CONSTRAINT FK_AJUSTE_SAIDA_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_ajuste_entrada
(
    id BIGINT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (id),
    CONSTRAINT FK_AJUSTE_ENTRADA_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_fabricacao
(
    id                BIGINT         NOT NULL AUTO_INCREMENT,
    item_principal_id BIGINT         NOT NULL,
    quantidade        DECIMAL(10, 2) NOT NULL,
    fabricacao_pai_id BIGINT NULL,
    venda_id          BIGINT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_FABRICACAO_ITEM
    FOREIGN KEY (item_principal_id) REFERENCES tb_item (id),
    CONSTRAINT FK_FABRICACAO_FABRICACAO_PAI
    FOREIGN KEY (fabricacao_pai_id) REFERENCES tb_fabricacao (id),
    CONSTRAINT FK_FABRICACAO_VENDA
    FOREIGN KEY (venda_id) REFERENCES tb_venda (id),
    CONSTRAINT FK_FABRICACAO_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (id) REFERENCES tb_movimentacao_estoque (id)
    );

CREATE TABLE IF NOT EXISTS tb_lancamento_financeiro
(
    id                      BIGINT         NOT NULL AUTO_INCREMENT,
    confeitaria_id          BIGINT         NOT NULL,
    criado_em               DATETIME       NOT NULL,
    pessoa_id               BIGINT         NOT NULL,
    tipo_lancamento         VARCHAR(50)    NOT NULL,
    lancamento_pai_id       BIGINT NULL,
    status_lancamento       VARCHAR(30)    NOT NULL,
    movimentacao_estoque_id BIGINT         NOT NULL,
    forma_pagamento         VARCHAR(50) NULL,
    data_lancamento         DATETIME       NOT NULL,
    data_vencimento         DATETIME       NOT NULL,
    descricao               VARCHAR(255)   NOT NULL,
    observacao              TEXT NULL,
    valor_lancamento        DECIMAL(10, 2) NOT NULL,
    valor_desconto          DECIMAL(10, 2) NOT NULL DEFAULT 0,
    valor_acrescimo         DECIMAL(10, 2) NOT NULL DEFAULT 0,
    data_compensacao        DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_LANCAMENTO_FINANCEIRO_CONFEITARIA
    FOREIGN KEY (confeitaria_id) REFERENCES tb_confeitaria (id),
    CONSTRAINT FK_LANCAMENTO_FINANCEIRO_PESSOA
    FOREIGN KEY (pessoa_id) REFERENCES tb_pessoa (id),
    CONSTRAINT FK_LANCAMENTO_FINANCEIRO_MOVIMENTACAO_ESTOQUE
    FOREIGN KEY (movimentacao_estoque_id) REFERENCES tb_movimentacao_estoque (id),
    CONSTRAINT FK_LANCAMENTO_FINANCEIRO_LANCAMENTO_PAI
    FOREIGN KEY (lancamento_pai_id) REFERENCES tb_lancamento_financeiro (id)
    );

CREATE TABLE IF NOT EXISTS tb_quitacao
(
    id              BIGINT         NOT NULL AUTO_INCREMENT,
    lancamento_id   BIGINT         NOT NULL,
    data_quitacao   DATETIME       NOT NULL,
    valor_quitado   DECIMAL(10, 2) NOT NULL,
    forma_pagamento VARCHAR(50)    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_quitacoes_lancamento
    FOREIGN KEY (lancamento_id) REFERENCES tb_lancamento_financeiro (id)
    );

CREATE TABLE IF NOT EXISTS tb_preco_item (

    id                 BIGINT         NOT NULL AUTO_INCREMENT,
    item_id            BIGINT         NOT NULL,
    preco_unitario     DECIMAL(10, 2) NOT NULL,
    data_inicio        DATETIME       NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT FK_PRECO_ITEM_ITEM
    FOREIGN KEY (item_id) REFERENCES tb_item (id)
);
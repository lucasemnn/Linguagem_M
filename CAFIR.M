let
    // Definir a função personalizada para processar cada link
    ProcessarLink = (numero) as table =>
        let
            // Verificar se o número é menor que 10 e adicionar um zero à frente se necessário
            numeroTexto = if numero < 10 then Text.PadStart(Text.From(numero), 2, "0") else Text.From(numero),

            // Construir o URL do link com base no número fornecido
            url = "https://dadosabertos.rfb.gov.br/CAFIR/K3243.K34313DP.D40109.PARTE" & numeroTexto,

            // Importar os dados do link como um arquivo CSV de largura fixa e nomear as colunas
            Fonte = Csv.Document(Web.Contents(url),13,{0, 8, 17, 30, 85, 87, 143, 183, 185, 225, 233, 241, 244, 245},ExtraValues.Ignore,1252),

            // Adicionar uma coluna de identificação para cada link
            AdicionarIdentificacao = Table.AddColumn(Fonte, "ID_LINK", each "PARTE "&numeroTexto),

            // Renomear as colunas para os nomes especificados
            ColunasRenomeadas = Table.RenameColumns(AdicionarIdentificacao, {
                {"Column1", "NIRF"},
                {"Column2", "AREA_TOT_IMO"},
                {"Column3", "CD_IMO_INCRA"},
                {"Column4", "NM_IMO_RUR"},
                {"Column5", "SIT_IMO"},
                {"Column6", "LOGRADOURO"},
                {"Column7", "DISTRITO"},
                {"Column8", "UF_IMO"},
                {"Column9", "MUNICIPIO_IMO"},
                {"Column10", "CEP"},
                {"Column11", "DT_AT_CAD"},
                {"Column12", "IMUNE_ISENTO"},
                {"Column13", "CD_SNCR"}
            }),

            // Converter a coluna 'DT_AT_CAD' para o formato de data 'DD/MM/AAAA'
            DataFormatada = Table.TransformColumns(ColunasRenomeadas, {"DT_AT_CAD", each Date.FromText(Text.Middle(_, 0, 4) & "-" & Text.Middle(_, 4, 2) & "-" & Text.Middle(_, 6, 2)), type date}),

            // Formatar a data para 'DD/MM/AAAA'
            DataFinal = Table.TransformColumns(DataFormatada, {"DT_AT_CAD", each Date.ToText(_, "dd/MM/yyyy"), type text}),

            // Adicionar vírgula entre o último caractere e o restante dos caracteres na coluna de área
            AreaComVirgula = Table.TransformColumns(DataFinal, {"AREA_TOT_IMO", each Text.Combine({Text.Start(_, Text.Length(_) - 1), "," & Text.End(_, 1)}, "")}),

            // Identificar automaticamente os tipos de dados de cada coluna
            TiposDeDadosIdentificados = Table.TransformColumnTypes(AreaComVirgula, {
                {"AREA_TOT_IMO", type number},
                 {"DT_AT_CAD", type date}

            }),
            // Remover valores errados da coluna 'DT_AT_CAD' e substituir por vazio
            TabelaSemErros = Table.ReplaceErrorValues(TiposDeDadosIdentificados, {{"DT_AT_CAD", null}})
        in
            TabelaSemErros,

    // Gerar uma lista de números de 1 a 20
    ListaNumeros = List.Numbers(1, 20),

    // Aplicar a função personalizada a cada número da lista para obter os dados de cada link
    ListaTabelas = List.Transform(ListaNumeros, each ProcessarLink(_)),

    // Combinar todas as tabelas individuais em uma única tabela consolidada
    TabelaConsolidada = Table.Combine(ListaTabelas),

    //Filtra os estados da aréa de atuação do Banco
    FiltroUF = Table.SelectRows(TabelaConsolidada, each [UF_IMO] = "AL" or [UF_IMO] = "BA" or [UF_IMO] = "MA" or [UF_IMO] = "CE" or [UF_IMO] = "PB" or [UF_IMO] = "PI" or [UF_IMO] = "RN" or [UF_IMO] = "SE" or [UF_IMO] = "PE" or [UF_IMO] = "ES" or [UF_IMO] = "MG")
in
    FiltroUF
window.addEventListener("load", function () {
  /** @type {HTMLParagraphElement} */
  const _currentUser = document.querySelector("#currentUser");
  /** @type {HTMLDivElement} */
  const _spinner = document.querySelector("#spinner");
  /** @type {HTMLDivElement} */
  const _listas = document.querySelector("#listas");
  /** @type {HTMLTableSectionElement} */
  const _tablebody = document.querySelector("#listas table tbody");

  const sasjs = new SASjs.default({
    appLoc: "/Public/app/ICL",
    serverType: "SASVIYA",
    serverUrl: "",
    debug: false,
    loginMechanism: "Redirected",
  });

  async function checkUserLoggedIn() {
    await sasjs.checkSession().then((response) => {
      let responseJson;
      try {
        responseJson = response;
      } catch (e) {
        console.error(e);
      }
      if (responseJson && responseJson.status === 449) {
        checkUserLoggedIn();
      } else if (responseJson && response.isLoggedIn) {
        _currentUser.innerText = response.userName;
        appinit();
      }
    });
  }

  checkUserLoggedIn();

  /* APPINIT */
  async function appinit() {
    await sasjs.request("jobs/appinit", null).then((response) => {
      let responseJson;
      try {
        responseJson = response;
      } catch (e) {
        console.error(e);
      }
      if (responseJson && responseJson.status === 449) {
        appinit();
      } else if (responseJson && responseJson.listas) {
        createTableListas(responseJson.listas);
      }
    });
  }

  function createTableListas(listas) {
    const listas_permitidas = [
      "LISTA_PESSOA_NOME_CPF",
      "LISTA_WHITE_LIST",
      "LISTA_COMUNICADOS_COAF",
      "LISTA_RESTRITIVO_INTERNO",
    ];

    clearTable(null, _tablebody);

    listas.forEach((lista) => {
      const tr = document.createElement("tr");
      const td1 = document.createElement("td");
      const td2 = document.createElement("td");

      td1.innerText = lista["LIST_NAME"];

      td2.innerHTML = `<button id=\"${lista["TABLE_REFERENCE"]}_VER\" value=\"${lista["TABLE_REFERENCE"]}\" class=\"btn btn-success\"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path d="M279.6 160.4C282.4 160.1 285.2 160 288 160C341 160 384 202.1 384 256C384 309 341 352 288 352C234.1 352 192 309 192 256C192 253.2 192.1 250.4 192.4 247.6C201.7 252.1 212.5 256 224 256C259.3 256 288 227.3 288 192C288 180.5 284.1 169.7 279.6 160.4zM480.6 112.6C527.4 156 558.7 207.1 573.5 243.7C576.8 251.6 576.8 260.4 573.5 268.3C558.7 304 527.4 355.1 480.6 399.4C433.5 443.2 368.8 480 288 480C207.2 480 142.5 443.2 95.42 399.4C48.62 355.1 17.34 304 2.461 268.3C-.8205 260.4-.8205 251.6 2.461 243.7C17.34 207.1 48.62 156 95.42 112.6C142.5 68.84 207.2 32 288 32C368.8 32 433.5 68.84 480.6 112.6V112.6zM288 112C208.5 112 144 176.5 144 256C144 335.5 208.5 400 288 400C367.5 400 432 335.5 432 256C432 176.5 367.5 112 288 112z"/></svg></button>`;
      td2.style.width = "0";

      tr.appendChild(td1);
      tr.appendChild(td2);

      if (lista["GERENTE"] !== ".") {
        const td3 = document.createElement("td");
        const td4 = document.createElement("td");

        if (listas_permitidas.indexOf(lista["TABLE_REFERENCE"]) > -1) {
          td3.innerHTML = `<button id=\"${lista["TABLE_REFERENCE"]}_EDITAR\" value=\"${lista["TABLE_REFERENCE"]}\" class=\"btn btn-success\"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path d="M362.7 19.32C387.7-5.678 428.3-5.678 453.3 19.32L492.7 58.75C517.7 83.74 517.7 124.3 492.7 149.3L444.3 197.7L314.3 67.72L362.7 19.32zM421.7 220.3L188.5 453.4C178.1 463.8 165.2 471.5 151.1 475.6L30.77 511C22.35 513.5 13.24 511.2 7.03 504.1C.8198 498.8-1.502 489.7 .976 481.2L36.37 360.9C40.53 346.8 48.16 333.9 58.57 323.5L291.7 90.34L421.7 220.3z"/></svg></button>`;
          td3.style.width = "0";
        } else {
          td3.innerHTML = `<button class=\"btn btn-secondary\" disabled><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path d="M362.7 19.32C387.7-5.678 428.3-5.678 453.3 19.32L492.7 58.75C517.7 83.74 517.7 124.3 492.7 149.3L444.3 197.7L314.3 67.72L362.7 19.32zM421.7 220.3L188.5 453.4C178.1 463.8 165.2 471.5 151.1 475.6L30.77 511C22.35 513.5 13.24 511.2 7.03 504.1C.8198 498.8-1.502 489.7 .976 481.2L36.37 360.9C40.53 346.8 48.16 333.9 58.57 323.5L291.7 90.34L421.7 220.3z"/></svg></button>`;
          td3.style.width = "0";
        }

        td4.innerHTML = `<button id=\"${lista["TABLE_REFERENCE"]}_EXCLUIR\" value=\"${lista["TABLE_REFERENCE"]}\" class=\"btn btn-danger\"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path d="M135.2 17.69C140.6 6.848 151.7 0 163.8 0H284.2C296.3 0 307.4 6.848 312.8 17.69L320 32H416C433.7 32 448 46.33 448 64C448 81.67 433.7 96 416 96H32C14.33 96 0 81.67 0 64C0 46.33 14.33 32 32 32H128L135.2 17.69zM394.8 466.1C393.2 492.3 372.3 512 346.9 512H101.1C75.75 512 54.77 492.3 53.19 466.1L31.1 128H416L394.8 466.1z"/></svg></button>`;
        td4.style.width = "0";

        tr.appendChild(td3);
        tr.appendChild(td4);
      }

      _tablebody.appendChild(tr);
    });

    listas.forEach((lista) => {
      const btnVer = document.querySelector(`#${lista["TABLE_REFERENCE"]}_VER`);
      const btnVerVoltar = document.querySelector("#ver_lista button");

      const btnExcluir = document.querySelector(
        `#${lista["TABLE_REFERENCE"]}_EXCLUIR`
      );
      const btnExcluirVoltar = document.querySelector(
        "#excluir_lista button:last-child"
      );

      btnVer.addEventListener("click", function () {
        _listas.style.display = "none";
        _spinner.style.display = "";
        document.querySelector("#ver_lista > div > span").innerText =
          lista["LIST_NAME"];
        getdata(btnVer.value);
      });

      btnVerVoltar.addEventListener("click", function () {
        renderHome("#ver_lista", false);
        _listas.style.display = "";
      });

      if (lista["GERENTE"] !== ".") {
        btnExcluir.addEventListener("click", function () {
          renderDelete(lista["LIST_NAME"], btnExcluir.value);
        });

        btnExcluirVoltar.addEventListener("click", function () {
          renderHome("#excluir_lista", false);
        });

        if (listas_permitidas.indexOf(lista["TABLE_REFERENCE"]) > -1) {
          const btnEditar = document.querySelector(
            `#${lista["TABLE_REFERENCE"]}_EDITAR`
          );

          btnEditar.addEventListener("click", function () {
            _listas.style.display = "none";
            _spinner.style.display = "";
            document.querySelector("#editar_lista > div > span").innerText =
              lista["LIST_NAME"];
            renderUpdate(btnEditar.value);
          });
        }
      }
    });

    const btnEditarVoltar = document.querySelector("#editar_lista button");

    btnEditarVoltar.addEventListener("click", function () {
      const _btnEnviar = document.querySelector("#editar_lista_enviar button");
      _btnEnviar.removeEventListener("click", uploaddata);

      renderHome("#editar_lista", false);
      _listas.style.display = "";

      listas_permitidas.forEach((e) => {
        document.querySelector(`#${e}`).style.display = "none";
      });
    });

    const btnCriar = document.querySelector("#criar_lista_btn");
    const btnCriarVoltar = document.querySelector(
      "#criar_lista button:last-child"
    );

    btnCriar.addEventListener("click", function () {
      renderCreate();
    });

    btnCriarVoltar.addEventListener("click", function () {
      renderHome("#criar_lista", false);
      _listas.style.display = "";
    });

    const btnBuscaUnificada = document.querySelector("#busca_unificada_btn");

    btnBuscaUnificada.addEventListener("click", function () {
      busca_unificada_func();
    });

    _spinner.style.display = "none";
    _listas.style.display = "";
  }
  /* APPINIT END */

  /* GETDATA */
  async function getdata(value) {
    await sasjs.request("jobs/getdata", { [value]: [{}] }).then((response) => {
      let responseJson;
      try {
        responseJson = response;
      } catch (e) {
        console.error(e);
      }
      if (responseJson && responseJson.lista) {
        createTableView(responseJson.lista);
      }
    });
  }

  function createTableView(lista) {
    const _headers = document.querySelector("#ver_lista thead tr");
    const _viewbody = document.querySelector("#ver_lista tbody");
    const _ver_lista = document.querySelector("#ver_lista");
    const _filter = document.querySelector("#filter");

    clearTable(_headers, _viewbody);
    _filter.value = "";

    if (lista[0]) {
      let colunas = Object.keys(lista[0]);

      colunas.forEach((col) => {
        const th = document.createElement("th");
        th.scope = "col";
        th.innerText = col;
        _headers.appendChild(th);
      });

      lista.forEach((linha) => {
        const tr = document.createElement("tr");
        colunas.forEach((col) => {
          const td = document.createElement("td");
          td.innerText = linha[col];
          tr.appendChild(td);
        });

        _viewbody.appendChild(tr);
      });
    }

    _spinner.style.display = "none";
    _ver_lista.style.display = "";
  }
  /* GETDATA END */

  /* UPLOADDATA */
  function renderUpdate(value) {
    const _btnEnviar = document.querySelector("#editar_lista_enviar button");
    const _editar_lista = document.querySelector("#editar_lista");
    const _form_lista = document.querySelector(`#${value}`);

    _btnEnviar.value = value;
    _btnEnviar.addEventListener("click", uploaddata);

    _spinner.style.display = "none";
    _editar_lista.style.display = "";
    _form_lista.style.display = "";
  }

  async function uploaddata() {
    const value = document.querySelector("#editar_lista_enviar button").value;

    const _input = document.querySelectorAll(`#${value} input`);
    const _select = document.querySelectorAll(`#${value} select`);
    const _textarea = document.querySelectorAll(`#${value} textarea`);

    let dataObject = { [value]: [{}] };
    let mensagem = "";

    let cidade = "";
    let uf = "";

    let erro = false;

    _input.forEach((e) => {
      if (e.type === "checkbox" && e.checked) {
        if (dataObject[value][0][e.name]) {
          dataObject[value][0][e.name] = `${dataObject[value][0][e.name]},${
            e.value
          }`;
        } else {
          dataObject[value][0][e.name] = e.value;
        }
      } else if (
        e.type !== "checkbox" &&
        e.name !== "CIDADE" &&
        e.name !== "UF" &&
        e.name !== "CPF_CNPJ"
      ) {
        dataObject[value][0][e.name] = e.value;
      } else if (e.name === "CPF_CNPJ") {
        const cpf_cnpj = e.value.replace(/[^0-9]/gm, "");

        if (cpf_cnpj.length !== 11 && cpf_cnpj.length !== 14) {
          mensagem = "CPF/CNPJ inválido!";
          erro = true;
        } else {
          dataObject[value][0]["CPF_CNPJ"] = cpf_cnpj;

          if (value === "LISTA_COMUNICADOS_COAF") {
            if (cpf_cnpj.length === 11) {
              dataObject[value][0]["PF_PJ"] = "PF";
            } else {
              dataObject[value][0]["PF_PJ"] = "PJ";
            }
          }
        }
      } else if (e.name === "CIDADE") {
        cidade = e.value;
      } else if (e.name === "UF") {
        uf = e.value;
      }
    });

    if (cidade !== "" && uf !== "") {
      dataObject[value][0]["CIDADE_UF"] = `${cidade} - ${uf}`;
    }

    _select.forEach((e) => {
      dataObject[value][0][e.name] = e.options[e.selectedIndex].value;
    });

    _textarea.forEach((e) => {
      dataObject[value][0][e.name] = e.value;
    });

    console.log(dataObject);

    if (erro) {
      toast(mensagem);
    } else {
      renderHome("#editar_lista", true);

      await sasjs.request("jobs/uploaddata", dataObject).then((response) => {
        let responseJson;
        try {
          responseJson = response;
        } catch (e) {
          console.error(e);
        }
        if (responseJson) {
          mensagem = responseJson.resposta[0]["TEXTO"];
        }
      });

      appinit();
      toast(mensagem);
    }
  }
  /* UPLOADDATA END */

  /* DISABLEDATA */
  function renderDelete(lista, value) {
    const _excluir_lista = document.querySelector("#excluir_lista");
    const _span = document.querySelector("#excluir_lista div span");
    const _btnConfirmar = document.querySelector(
      "#excluir_lista button:first-child"
    );

    _btnConfirmar.addEventListener("click", function () {
      disabledata(value);
    });

    _span.innerText = lista;

    _excluir_lista.style.display = "";
  }

  async function disabledata(value) {
    renderHome("#excluir_lista", true);

    let mensagem = "";
    await sasjs
      .request("jobs/disabledata", { [value]: [{}] })
      .then((response) => {
        let responseJson;
        try {
          responseJson = response;
        } catch (e) {
          console.error(e);
        }
        if (responseJson) {
          mensagem = responseJson.resposta[0]["TEXTO"];
        }
      });

    appinit();
    toast(mensagem);
  }
  /* DISABLEDATA END */

  /* CREATEDATA */
  function renderCreate() {
    const _criar_lista = document.querySelector("#criar_lista");
    const _btnConfirmar = document.querySelector(
      "#criar_lista button:first-child"
    );

    const _criar_lista_name = document.querySelector("#criar_lista_name");
    const _criar_lista_file = document.querySelector("#criar_lista_file");

    _btnConfirmar.addEventListener("click", function () {
      createdata(_criar_lista_name.value, _criar_lista_file);
    });

    _criar_lista.style.display = "";
  }

  async function createdata(name, input) {
    let name_1 = name.normalize("NFD");
    let name_2 = name_1.replace(/[\u0300-\u036f]/g, "");
    let name_3 = name_2.toUpperCase();
    let name_4 = name_3.replace(/ /g, "_");

    let name_5;

    if (name_4.length > 29) {
      name_5 = name_4.slice(0, 29);
    } else {
      name_5 = name_4;
    }

    const tableName = name;
    const tableRef = name_5;

    const myfile = input.files[0];
    const myregex = /\.(csv|xlsx)$/;
    const mymatch = myfile.name.match(myregex)[1];

    renderHome("#criar_lista", true);

    let mensagem = "";
    if (myfile) {
      if (mymatch === "csv" || mymatch === "xlsx") {
        await sasjs
          .uploadFile(
            "jobs/createdata",
            [{ file: myfile, fileName: myfile.name }],
            { tableName: tableName, tableRef: tableRef, fileType: mymatch }
          )
          .then((response) => {
            let responseJson;
            try {
              responseJson = response;
            } catch (e) {
              console.error(e);
            }
            if (responseJson) {
              mensagem = responseJson.resposta[0]["TEXTO"];
            }
          });
      }
    }

    appinit();
    toast(mensagem);
  }
  /* CREATEDATA END */

  /* TOAST */
  function toast(mensagem) {
    /** @type {HTMLDivElement} */
    const _toast = document.querySelector("#toast");
    /** @type {HTMLDivElement} */
    const _toastBody = document.querySelector("#toast>.toast-body");
    /** @type {HTMLDivElement} */
    const _toastButton = document.querySelector(
      "#toast>.toast-header>.btn-close"
    );

    if (_toast.classList.contains("fadeOut")) {
      _toast.classList.remove("fadeOut");
    }

    _toast.style.display = "";
    _toastBody.innerText = mensagem;
    _toastButton.addEventListener("click", () => {
      renderHome("#toast", false);
    });

    setTimeout(() => {
      _toast.classList.add("fadeOut");
      setTimeout(() => {
        renderHome("#toast", false);
      }, 2000);
    }, 3000);
  }
  /* TOAST END */

  /* UTILITY */
  function clearTable(thead, tbody) {
    if (!(thead === null)) {
      while (thead.firstChild) {
        thead.removeChild(thead.lastChild);
      }
    }

    if (!(tbody === null)) {
      while (tbody.firstChild) {
        const lastRow = tbody.lastChild;
        while (lastRow.firstChild) {
          lastRow.removeChild(lastRow.lastChild);
        }
        tbody.removeChild(tbody.lastChild);
      }
    }
  }

  function renderHome(element, reload) {
    document.querySelector(element).style.display = "none";

    if (reload) {
      _listas.style.display = "none";
      _spinner.style.display = "";
    }
  }
  /* UTILITY END */

  /* BUSCA UNIFICADA */
  async function busca_unificada_func() {
    const buscaUnificada = document.querySelector("#busca_unificada");

    let cpf_cnpj = buscaUnificada.value;

    cpf_cnpj = cpf_cnpj.replace(/[^0-9]/gm, "");

    if (cpf_cnpj.length === 11 || cpf_cnpj.length === 14) {
      let dataObject = { fromjs: [{ cpf: cpf_cnpj }] };

      await sasjs
        .request("jobs/buscaunificada", dataObject)
        .then((response) => {
          let responseJson;
          try {
            responseJson = response;
          } catch (e) {
            console.error(e);
          }
          if (responseJson) {
            createUnifiedView(responseJson);
          }
        });
    }
  }

  function createUnifiedView(lista) {
    let listas = [
      {
        nome: "Contas Encerradas",
        valor: lista?.contas_encerradas,
      },
      {
        nome: "Novos Clientes",
        valor: lista?.novos_clientes,
      },
      {
        nome: "Comunicados ao Coaf",
        valor: lista?.comunicados_coaf,
      },
      {
        nome: "Indice Internacional",
        valor: lista?.indice_internacional,
      },
      {
        nome: "Pep Aml",
        valor: lista?.pep_aml,
      },
      {
        nome: "Pep Aml Relacionado",
        valor: lista?.pep_aml_relacionado,
      },
      {
        nome: "Pep Aml Titular",
        valor: lista?.pep_aml_titular,
      },
      {
        nome: "Pep Serasa",
        valor: lista?.pep_serasa,
      },
      {
        nome: "Pep Siscoaf",
        valor: lista?.pep_siscoaf,
      },
      {
        nome: "Pessoa em Lista",
        valor: lista?.pessoa_nome_cpf,
      },
      {
        nome: "Mídias Desabonadoras",
        valor: lista?.pessoa_noticias,
      },
      {
        nome: "Restritiva Internacional",
        valor: lista?.restritiva_internacional,
      },
      {
        nome: "Restritiva Nacional",
        valor: lista?.restritiva_nacional,
      },
      {
        nome: "Restritivo Interno",
        valor: lista?.restritivo_interno,
      },
      {
        nome: "White List",
        valor: lista?.white_list,
      },
    ];

    const tabelas_div = document.querySelector("#tabelas");

    listas.forEach((list) => {
      const strong = document.createElement("strong");
      strong.innerText = list?.nome;
      const hr = document.createElement("hr");
      const br = document.createElement("br");
      const table = document.createElement("table");
      table.classList.add("table");
      table.classList.add("table-hover");
      const thead = document.createElement("thead");
      const tbody = document.createElement("tbody");

      const th_row = document.createElement("tr");

      if (list?.valor[0]) {
        const colunas = Object.keys(list?.valor[0]);

        colunas.forEach((col) => {
          const th = document.createElement("th");
          th.scope = "col";
          th.innerText = col;
          th_row.appendChild(th);
        });

        list.valor.forEach((linha) => {
          const tr = document.createElement("tr");
          colunas.forEach((col) => {
            const td = document.createElement("td");
            td.innerText = linha[col];
            tr.appendChild(td);
          });
          tbody.appendChild(tr);
        });

        thead.appendChild(th_row);
        table.appendChild(thead);
        table.appendChild(tbody);
        tabelas_div.appendChild(strong);
        tabelas_div.appendChild(hr);
        tabelas_div.appendChild(table);
        tabelas_div.appendChild(br);
      }
    });

    const buscaUnificada = document.querySelector("#busca_unificada");

    _listas.style.display = "none";
    buscaUnificada.style.display = "";
  }
  /* BUSCA UNIFICADA END */
});

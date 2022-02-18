window.addEventListener("load", function () {
    /** @type {HTMLParagraphElement} */
    const _currentUser = document.querySelector("#currentUser");
    /** @type {HTMLDivElement} */
    const _spinner = document.querySelector("#spinner");
    /** @type {HTMLDivElement} */
    const _listas = document.querySelector("#listas");
    /** @type {HTMLTableSectionElement} */
    const _tablebody = this.document.querySelector("#listas table tbody");

    const sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
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
        await sasjs.request("services/common/appinit", null).then((response) => {
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
        clearTable(null, _tablebody);

        listas.forEach((lista) => {
            const tr = document.createElement("tr");
            const td1 = document.createElement("td");
            const td2 = document.createElement("td");
            const td3 = document.createElement("td");
            const td4 = document.createElement("td");
            td1.innerText = lista['LIST_NAME'];
            td2.innerHTML = `<button id=\"${lista['TABLE_REFERENCE']}_VER\" value=\"${lista['TABLE_REFERENCE']}\" class=\"btn btn-secondary\"><img src=\"assets/img/eye.svg\"></button>`;
            td3.innerHTML = `<button id=\"${lista['TABLE_REFERENCE']}_EDITAR\" value=\"${lista['TABLE_REFERENCE']}\" class=\"btn btn-secondary\"><img src=\"assets/img/pen.svg\"></button>`;
            td4.innerHTML = `<button id=\"${lista['TABLE_REFERENCE']}_EXCLUIR\" value=\"${lista['TABLE_REFERENCE']}\" class=\"btn btn-secondary\"><img src=\"assets/img/trash.svg\"></button>`;
            td2.style.width = "0";
            td3.style.width = "0";
            td4.style.width = "0";
            tr.appendChild(td1);
            tr.appendChild(td2);
            tr.appendChild(td3);
            tr.appendChild(td4);
            _tablebody.appendChild(tr);
        });

        listas.forEach((lista) => {
            const btnVer = document.querySelector(`#${lista['TABLE_REFERENCE']}_VER`);
            const btnVerVoltar = document.querySelector("#ver_lista button");

            const btnEditar = document.querySelector(`#${lista['TABLE_REFERENCE']}_EDITAR`);
            const btnEditarVoltar = document.querySelector("#editar_lista button");

            const btnExcluir = document.querySelector(`#${lista['TABLE_REFERENCE']}_EXCLUIR`);
            const btnExcluirVoltar = document.querySelector("#excluir_lista button:last-child");

            const btnCriar = document.querySelector("#criar_lista_btn");
            const btnCriarVoltar = document.querySelector("#criar_lista button:last-child");

            btnVer.addEventListener("click", function () {
                _spinner.style.display = "";
                _listas.style.display = "none";
                document.querySelector("#ver_lista > div > span").innerText = lista['LIST_NAME'];
                getdata(btnVer.value);
            });

            btnVerVoltar.addEventListener("click", function () {
                document.querySelector("#ver_lista").style.display = "none";
                _listas.style.display = "";
            })

            btnEditar.addEventListener("click", function () {
                _spinner.style.display = "";
                _listas.style.display = "none";
                document.querySelector("#editar_lista > div > span").innerText = lista['LIST_NAME'];
                renderUpdate(btnEditar.value);
            });

            btnEditarVoltar.addEventListener("click", function () {
                document.querySelector("#editar_lista").style.display = "none";
                _listas.style.display = "";
            })

            btnExcluir.addEventListener("click", function () {
                renderDelete(lista['LIST_NAME'], btnExcluir.value);
            });

            btnExcluirVoltar.addEventListener("click", function () {
                document.querySelector("#excluir_lista").style.display = "none";
                _listas.style.display = "";
            });

            btnCriar.addEventListener("click", function () {
                renderCreate();
            });

            btnCriarVoltar.addEventListener("click", function () {
                document.querySelector("#criar_lista").style.display = "none";
                _listas.style.display = "";
            });
        })

        _spinner.style.display = "none";
        _listas.style.display = "";
    }
    /* APPINIT END */


    /* GETDATA */
    async function getdata(value) {
        await sasjs.request("services/common/getdata", { [value]: [{}] }).then((response) => {
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
    /* GETDATA END */


    /* UPLOADDATA */
    function renderUpdate(value) {
        const _editar_lista = document.querySelector("#editar_lista");
        const _fileInput = document.querySelector("#editar_lista .input-group input");
        const _btnEnviar = document.querySelector("#editar_lista .input-group button");

        _btnEnviar.addEventListener("click", function () {
            uploaddata(_fileInput, value);
        });

        _spinner.style.display = "none";
        _editar_lista.style.display = "";
    }

    async function uploaddata(input, value) {
        const myfile = input.files[0];

        if (myfile) {
            await sasjs.uploadFile('services/common/uploaddata', [{ "file": myfile, "fileName": myfile.name }], { "tableRef": value }).then((response) => {
                let responseJson;
                try {
                    responseJson = response;
                } catch (e) {
                    console.error(e);
                }
                if (responseJson) {
                    console.log(responseJson);
                }
            });
        }
    }
    /* UPLOADDATA END */


    /* DISABLEDATA */
    function renderDelete(lista, value) {
        const _excluir_lista = document.querySelector("#excluir_lista");
        const _span = document.querySelector("#excluir_lista div span");
        const _btnConfirmar = document.querySelector("#excluir_lista button:first-child");

        _btnConfirmar.addEventListener("click", function () {
            disabledata(value);
        });

        _span.innerText = lista;

        _excluir_lista.style.display = "";
    }

    async function disabledata(value) {
        await sasjs.request("services/common/disabledata", { [value]: [{}] }).then((response) => {
            let responseJson;
            try {
                responseJson = response;
            } catch (e) {
                console.error(e);
            }
            if (responseJson) {
                console.log(responseJson);
            }
        });
    }
    /* DISABLEDATA END */


    /* CREATEDATA */
    function renderCreate() {
        const _criar_lista = document.querySelector("#criar_lista");
        const _btnConfirmar = document.querySelector("#criar_lista button:first-child");

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
        const tableRef = name_4;

        const myfile = input.files[0];

        if (myfile) {
            await sasjs.uploadFile('services/common/createdata', [{ "file": myfile, "fileName": myfile.name }], { "tableName": tableName, "tableRef": tableRef }).then((response) => {
                let responseJson;
                try {
                    responseJson = response;
                } catch (e) {
                    console.error(e);
                }
                if (responseJson) {
                    console.log(responseJson);
                }
            });
        }
    }
    /* CREATEDATA END */
});

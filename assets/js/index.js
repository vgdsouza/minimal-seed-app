window.addEventListener("load", function () {
    /** @type {HTMLParagraphElement} */
    const currentUser = document.querySelector("#currentUser");
    /** @type {HTMLDivElement} */
    const spinner = document.querySelector("#spinner");
    /** @type {HTMLDivElement} */
    const listas = document.querySelector("#listas");
    /** @type {HTMLTableSectionElement} */
    const tablebody = this.document.querySelector("#listas table tbody");


    const sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
    });

    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            currentUser.innerText = res.userName;
            appinit();
        }
    });

    /* APPINIT */
    async function appinit() {
        await sasjs.request("services/common/appinit", null).then((res) => {
            let responseJson;

            try {
                responseJson = res;
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
            tablebody.appendChild(tr);
        });

        listas.forEach((lista) => {
            const btnVer = document.querySelector(`#${lista['TABLE_REFERENCE']}_VER`);
            const btnEditar = document.querySelector(`#${lista['TABLE_REFERENCE']}_EDITAR`);
            const btnExcluir = document.querySelector(`#${lista['TABLE_REFERENCE']}_EXCLUIR`);
            const btnVerVoltar = document.querySelector("#ver_lista button");
            const btnEditarVoltar = document.querySelector("#editar_lista button");

            btnVer.addEventListener("click", function () {
                spinner.style.display = "";
                listas.style.display = "none";
                document.querySelector("#ver_lista > div > span").innerText = lista['LIST_NAME'];
                getdata(btnVer.value);
            });

            btnVerVoltar.addEventListener("click", function () {
                document.querySelector("#ver_lista").style.display = "none";
                listas.style.display = "";
            })

            btnEditar.addEventListener("click", function () {
                spinner.style.display = "";
                listas.style.display = "none";
                document.querySelector("#editar_lista > div > span").innerText = lista['LIST_NAME'];
                renderUpdate(btnEditar.value);
            });

            btnEditarVoltar.addEventListener("click", function () {
                document.querySelector("#editar_lista").style.display = "none";
                listas.style.display = "";
            })

            btnExcluir.addEventListener("click", function () {
                spinner.style.display = "";
                listas.style.display = "none";
            });
        })

        spinner.style.display = "none";
        listas.style.display = "";
    }
    /* APPINIT END */


    /* GETDATA */
    async function getdata(value) {
        const dataObject = {
            [value]: [{}]
        }

        await sasjs.request("services/common/getdata", dataObject).then((res) => {
            let responseJson;

            try {
                responseJson = res;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                getdata();
            } else if (responseJson) {
                createTableView(responseJson.lista);
            }
        });
    }

    function createTableView(lista) {
        const headers = document.querySelector("#ver_lista thead tr");
        const viewbody = document.querySelector("#ver_lista tbody");
        const ver_lista = document.querySelector("#ver_lista");

        clearTable(headers, viewbody);

        if (lista[0]) {
            let colunas = Object.keys(lista[0]);

            colunas.forEach((col) => {
                const th = document.createElement("th");
                th.scope = "col";
                th.innerText = col;
                headers.appendChild(th);
            });

            lista.forEach((linha) => {
                /** @type {HTMLTableRowElement} */
                const tr = document.createElement("tr");
                colunas.forEach((col) => {
                    /** @type {HTMLTableCellElement} */
                    const td = document.createElement("td");
                    td.innerText = linha[col];
                    tr.appendChild(td);
                });

                viewbody.appendChild(tr);
            });
        }

        spinner.style.display = "none";
        ver_lista.style.display = "";
    }

    function clearTable(thead, tbody) {
        while (thead.firstChild) {
            thead.removeChild(thead.lastChild);
        }

        while (tbody.firstChild) {
            /** @type {HTMLTableRowElement} */
            const lastRow = tbody.lastChild;
            while (lastRow.firstChild) {
                lastRow.removeChild(lastRow.lastChild);
            }
            tbody.removeChild(tbody.lastChild);
        }
    }
    /* GETDATA END */


    /* UPDATEDATA */
    function renderUpdate(value) {
        const editar_lista = document.querySelector("#editar_lista");
        const fileInput = document.querySelector("#editar_lista .input-group input");
        const btnEnviar = document.querySelector("#editar_lista .input-group button");

        btnEnviar.addEventListener("click", function () {
            updatedata(fileInput, value);
        });

        spinner.style.display = "none";
        editar_lista.style.display = "";
    }

    async function updatedata(input, value) {
        const chunkSize = 5 * 1024 * 1024; //chunk size is 5MB
        const myfile = input.files[0];

        if (myfile) {
            const numberOfChunks = Math.ceil(file.size / chunkSize);

            for (let i = 0; i < numberOfChunks; i++) {
                const chunkStart = chunkSize * i;
                const chunkEnd = Math.min(chunkStart + chunkSize, file.size);
                const chunk = file.slice(chunkStart, chunkEnd);
                const newFile = new File([chunk], file.name, { "type": file.type, "lastModified": file.lastModified });

                if (i === 0) {
                    await sasjs.uploadFile('services/common/updatedata', [{ "file": newFile, "fileName": myfile.name }], { "tableRef": value });
                } else {
                    await sasjs.uploadFile('services/common/appenddata', [{ "file": newFile, "fileName": myfile.name }], { "tableRef": value });
                }
            }
        }
    }
    /* UPDATEDATA END */
});

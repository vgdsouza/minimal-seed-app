window.addEventListener("load", function () {
    /** @type {HTMLParagraphElement} */
    const currentUser = document.querySelector("#currentUser");

    /** @type {HTMLDivElement} */
    const spinner = document.querySelector("#spinner");

    /** @type {HTMLDivElement} */
    const main = document.querySelector("#main");

    /** @type {HTMLSelectElement} */
    const tableselect = document.querySelector("#tableselect");

    /** @type {HTMLInputElement} */
    const tablefile = document.querySelector("#tablefile");

    /** @type {HTMLButtonElement} */
    const tablebutton = document.querySelector("#tablebutton");

    /** @type {HTMLTableElement} */
    const mytable = document.querySelector("#mytable");

    /** @type {HTMLTableRowElement} */
    const thead = document.querySelector("#thead");

    /** @type {HTMLTableSectionElement} */
    const tbody = document.querySelector("#tbody");

    const sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: false,
        loginMechanism: "Redirected"
    });

    if (!MOCK) {
        sasjs.checkSession().then((res) => {
            if (res.isLoggedIn) {
                currentUser.innerText = res.userName;
                appinit();
            }
        });
    } else {
        this.setTimeout(appinit, 1000);
    }

    /* APPINIT */
    async function appinit() {
        if (!MOCK) {
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
                    createSelectListas(responseJson.listas);
                }
            });
        } else {
            createSelectListas(appinitJson.listas);
        }
    }

    function createSelectListas(lists) {
        lists.forEach((list) => {
            /** @type {HTMLOptionElement} */
            const option = new Option();
            option.value = list['TABLE_REFERENCE'];
            option.text = list['LIST_NAME'];
            tableselect.options.add(option);
        });

        tablefile.value = "";
        spinner.style.display = "none";
        main.style.display = "flex";
    }
    /* APPINIT END */


    /* GETDATA */
    tableselect.addEventListener("change", getdata);

    async function getdata() {
        mytable.style.display = "none";

        clearTable();

        const val = String(tableselect.options[tableselect.selectedIndex].value);

        if (val === "") {
            tablefile.disabled = true;
        } else {
            const dataObject = {
                [val]: [{}]
            }

            if (!MOCK) {
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
            } else {
                setTimeout(createTableView, 1000, getdataJson.lista);
            }
        }

        mytable.style.display = "table";
        tablefile.value = "";
        tablefile.disabled = false;
    }

    function clearTable() {
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

    function createTableView(lista) {
        if (lista[0]) {
            let colunas = Object.keys(lista[0]);

            colunas.forEach((col) => {
                /** @type {HTMLTableCellElement} */
                const th = document.createElement("th");
                th.scope = "col";
                th.innerText = col;
                thead.appendChild(th);
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
                tbody.appendChild(tr);
            });
        }
    }
    /* GETDATA END */


    /* UPDATEDATA */
    tablefile.addEventListener("change", function () {
        if (!(tablefile.value === "")) {
            tablebutton.disabled = false;
        }
    });

    tablebutton.addEventListener("click", updatedata);

    async function updatedata() {
        tablefile.disabled = true;
        tablebutton.disabled = true;

        /** @type {File} */
        const myfile = tablefile.files[0];

        const val = String(tableselect.options[tableselect.selectedIndex].value);

        if (myfile) {
            await sasjs.uploadFile(
                'services/common/updatedata',
                [{ "file": myfile, "fileName": myfile.name }],
                { "tableRef": val }
            ).then((res) => {
                let responseJson;

                try {
                    responseJson = res;
                } catch (e) {
                    console.error(e);
                }

                if (responseJson && responseJson.status === 449) {
                    console.error(responseJson);
                } else if (responseJson) {
                    console.log(responseJson);
                }
            });
        }
    }
    /* UPDATEDATA END */
});

async function upload(file) {
    const chunkSize = 5 * 1024 * 1024; //chunk size is 5MB

    if (file) {
        const numberOfChunks = Math.ceil(file.size / chunkSize);

        for (let i = 0; i < numberOfChunks; i++) {
            const chunkStart = chunkSize * i;
            const chunkEnd = Math.min(chunkStart + chunkSize, file.size);
            const chunk = file.slice(chunkStart, chunkEnd);
            const newFile = new File([chunk], file.name, { "type": file.type, "lastModified": file.lastModified });

            if (i === 0) {
                await sasjs.uploadFile('services/common/upload', [{ file: newFile, fileName: file.name }], { "tableRef": val }).then(
                    (res) => {
                        if (res?.sasjsAbort) {
                            const error = `MAC: ${res.sasjsAbort[0].MAC}\n MSG: ${res.sasjsAbort[0].MSG}`;
                            console.error(error);
                        }
                    },
                    (err) => {
                        console.error(err);
                    }
                )
            } else {
                await sasjs.uploadFile('services/common/append', [{ file: newFile, fileName: file.name }], { "tableRef": val }).then(
                    (res) => {
                        console.log(res);
                    },
                    (err) => {
                        console.error(err);
                    }
                )
            }
        }
    }
}

const MOCK = true;

const appinitJson = {
    "START_DTTM": "15FEB22:12:53:46.342"
    , "listas":
        [
            { "LIST_NAME": "CEIS", "TABLE_REFERENCE": "LISTA_CEIS" }
            , { "LIST_NAME": "CNAE", "TABLE_REFERENCE": "LISTA_CNAE" }
            , { "LIST_NAME": "GAFI (HIGH RISK)", "TABLE_REFERENCE": "LISTA_GAFI_HIGH_RISK" }
            , { "LIST_NAME": "GAFI (IN PROGRESS)", "TABLE_REFERENCE": "LISTA_GAFI_IN_PROGRESS" }
            , { "LIST_NAME": "IBAMA", "TABLE_REFERENCE": "LISTA_IBAMA" }
            , { "LIST_NAME": "MUNICIPIO (FRONTEIRA", "TABLE_REFERENCE": "LISTA_MUNICIPIO_DE_FRONTEIRA" }
            , { "LIST_NAME": "MUNICIPIO (RISCO)", "TABLE_REFERENCE": "LISTA_MUNICIPIO_RISCO" }
            , { "LIST_NAME": "OFAC", "TABLE_REFERENCE": "LISTA_OFAC" }
            , { "LIST_NAME": "ONU (CONSOLIDADA)", "TABLE_REFERENCE": "LISTA_ONU_CONSOLIDADA" }
            , { "LIST_NAME": "PAIS (RISCO)", "TABLE_REFERENCE": "LISTA_PAIS_RISCO" }
            , { "LIST_NAME": "PAIS (RISCO EU)", "TABLE_REFERENCE": "LISTA_PAIS_RISCO_EU" }
            , { "LIST_NAME": "PAIS (RISCO ONU)", "TABLE_REFERENCE": "LISTA_PAIS_RISCO_ONU" }
            , { "LIST_NAME": "PARAISO FISCAL", "TABLE_REFERENCE": "LISTA_PARAISO_FISCAL" }
            , { "LIST_NAME": "PEP (AML)", "TABLE_REFERENCE": "LISTA_PEP_AML" }
            , { "LIST_NAME": "PEP (SERASA)", "TABLE_REFERENCE": "LISTA_PEP_SERASA" }
            , { "LIST_NAME": "PEP (SISCOAF)", "TABLE_REFERENCE": "LISTA_PEP_SISCOAF" }
            , { "LIST_NAME": "PESSOA/NOME/CPF", "TABLE_REFERENCE": "LISTA_PESSOA_NOME_CPF" }
            , { "LIST_NAME": "PROFISSOES", "TABLE_REFERENCE": "LISTA_PROFISSOES" }
            , { "LIST_NAME": "RESTRITIVO INTERNO", "TABLE_REFERENCE": "LISTA_RESTRITIVO_INTERNO_PLDFT" }
            , { "LIST_NAME": "RISCO (OFAC)", "TABLE_REFERENCE": "LISTA_RISCO_OFAC" }
            , { "LIST_NAME": "SANCAO (ARMAMENTOS)", "TABLE_REFERENCE": "LISTA_SANCAO_ARMAMENTOS" }
            , { "LIST_NAME": "SANCAO (INTERNA)", "TABLE_REFERENCE": "LISTA_SANCAO_INTERNA" }
            , { "LIST_NAME": "TRABALHO ESCRAVO", "TABLE_REFERENCE": "LISTA_TRABALHO_ESCRAVO" }
            , { "LIST_NAME": "UK BANK", "TABLE_REFERENCE": "LISTA_UK_BANCO" }
            , { "LIST_NAME": "UNIAO EUROPEIA", "TABLE_REFERENCE": "LISTA_UNIAO_EUROPEIA" }
        ]
    , "SYSUSERID": "visouz"
    , "MF_GETUSER": "visouz"
    , "SYS_JES_JOB_URI": "/jobExecution/jobs/f43475ed-c4d3-423b-bdac-15ebb35bd1e5"
    , "SYSJOBID": "1922922"
    , "_DEBUG": ""
    , "_PROGRAM": "/Public/app/ICL/services/common/appinit"
    , "SYSCC": "0"
    , "SYSERRORTEXT": ""
    , "SYSHOSTNAME": "bpn09au"
    , "SYSSCPL": "Linux"
    , "SYSSITE": "70288264"
    , "SYSVLONG": "V.03.05M0P111119"
    , "SYSWARNINGTEXT": ""
    , "END_DTTM": "15FEB22:12:53:46.420"
}

const getdataJson = {
    "START_DTTM": "15FEB22:12:55:28.362"
    , "lista":
        [
            { "ID": "1", "SUBCLASSE": "0111301", "DENOMINACAO": "Cultivo de arroz", "RISCO": "Baixo", "NR_RISCO": "100", "HORA_INICIO": "05:00", "HORA_FIM": "19:00", "STATUS": "1" }
            , { "ID": "2", "SUBCLASSE": "0111302", "DENOMINACAO": "Cultivo de milho", "RISCO": "Baixo", "NR_RISCO": "100", "HORA_INICIO": "05:00", "HORA_FIM": "19:00", "STATUS": "1" }
            , { "ID": "3", "SUBCLASSE": "0111303", "DENOMINACAO": "Cultivo de trigo", "RISCO": "Baixo", "NR_RISCO": "100", "HORA_INICIO": "05:00", "HORA_FIM": "19:00", "STATUS": "1" }
            , { "ID": "4", "SUBCLASSE": "3250706", "DENOMINACAO": "SERVIÇOS DE PRÓTESE DENTÁRIA", "RISCO": "Baixo", "NR_RISCO": "100", "HORA_INICIO": "09:00", "HORA_FIM": "18:00", "STATUS": "1" }
        ]
    , "SYSUSERID": "visouz"
    , "MF_GETUSER": "visouz"
    , "SYS_JES_JOB_URI": "/jobExecution/jobs/49ba7689-30a6-4d75-8e35-af73c3bf80c0"
    , "SYSJOBID": "1925540"
    , "_DEBUG": ""
    , "_PROGRAM": "/Public/app/ICL/services/common/getdata"
    , "SYSCC": "0"
    , "SYSERRORTEXT": ""
    , "SYSHOSTNAME": "bpn09au"
    , "SYSSCPL": "Linux"
    , "SYSSITE": "70288264"
    , "SYSVLONG": "V.03.05M0P111119"
    , "SYSWARNINGTEXT": ""
    , "END_DTTM": "15FEB22:12:55:28.441"
}

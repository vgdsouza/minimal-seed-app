/* window.onload para garantir que todo o HTML já foi carregado */
window.addEventListener("load", function () {
    /** @type {HTMLSelectElement} */
    const tableselect = document.querySelector("#tableselect");

    tableselect.addEventListener("change", getdata);

    async function getdata() {
        /** @type {HTMLTableElement} */
        const mytable = document.querySelector("#mytable");
        /** @type {HTMLDivElement} */
        const tablespinner = document.querySelector("#tablespinner");
        /** @type {HTMLButtonElement} */
        const tablebutton = document.querySelector("#tablebutton");
        /** @type {HTMLInputElement} */
        const tablefile = document.querySelector("#tablefile")

        mytable.style.display = "";  // No CSS está definido como None
        tablespinner.style.display = "flex";

        clearTable();

        const val = String(tableselect.options[tableselect.selectedIndex].value);

        if (!(val === "")) {
            const dataObject = {
                [val]: [{}]
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

        tablespinner.style.display = "";  // No CSS está definido como None
        mytable.style.display = "flex";
        tablefile.value = "";
        tablefile.disabled = false;
    }

    function clearTable() {
        /** @type {HTMLTableRowElement} */
        const theadrow = document.querySelector("#thead");
        /** @type {HTMLTableSectionElement} */
        const tbody = document.querySelector("#tbody");

        while (theadrow.firstChild) {
            theadrow.removeChild(theadrow.lastChild);
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
        /** @type {HTMLTableRowElement} */
        const thead = document.querySelector("#thead");
        /** @type {HTMLTableSectionElement} */
        const tbody = document.querySelector("#tbody");

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
});

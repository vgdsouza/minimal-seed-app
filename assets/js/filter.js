window.addEventListener("load", function () {
    /** @type {HTMLInputElement} */
    const tablefilterinput = document.querySelector("#tablefilterinput");

    /** @type {HTMLTableSectionElement} */
    const tbody = document.querySelector("#tbody");

    tablefilterinput.addEventListener("change", filtraTabela);

    function filtraTabela() {
        /** @type {String} */
        let textoBusca;
        /** @type {String} */
        let textoCelula;
        /** @type {HTMLTableRowElement} */
        let linhaAtual;
        /** @type {HTMLTableCellElement} */
        let celulaAtual;
        /** @type {Boolean} */
        let buscaEncontrada;

        textoBusca = tratamentoTextual(tablefilterinput.value);

        for (let linha of tbody.childNodes) {
            linhaAtual = linha;
            buscaEncontrada = false;

            for (let celula of linhaAtual.childNodes) {
                celulaAtual = celula;
                textoCelula = tratamentoTextual(celulaAtual.innerText);

                if (textoCelula.indexOf(textoBusca) > -1) {
                    buscaEncontrada = true;
                    break;
                }
            }

            if (buscaEncontrada) {
                linhaAtual.style.display = "";
            } else {
                linhaAtual.style.display = "none";
            }
        }
    }

    function tratamentoTextual(texto) {
        // n - Normalizado
        let texto_n = texto.normalize("NFD");
        // sa - Sem Acentos
        let texto_nsa = texto_n.replace(/[\u0300-\u036f]/g, "");
        // u - Uppercase
        let texto_nsau = texto_nsa.toUpperCase();

        return texto_nsau;
    }
});

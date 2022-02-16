window.addEventListener("load", function() {
    const _filter = document.querySelector("#filter");
    const _tbody = document.querySelector("#ver_lista table tbody");

    _filter.addEventListener("keyup", filtraTabela);

    function filtraTabela() {
        let textoBusca;
        let textoCelula;
        let linhaAtual;
        let celulaAtual;
        let buscaEncontrada;

        textoBusca = tratamentoTextual(_filter.value);

        for (let linha of _tbody.childNodes) {
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
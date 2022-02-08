window.addEventListener("load", function () {
    function filePromise(file) {
        const reader = new FileReader();

        return new Promise((resolve) => {
            reader.onload = () => {
                resolve(reader.result);
            };

            reader.readAsText(file);
        });
    }

    async function updatedata() {
        /** @type {HTMLInputElement} */
        const htmlFile = document.querySelector("#tablefile");
        /** @type {HTMLButtonElement} */
        const htmlButton = document.querySelector("#tablebutton");

        htmlFile.disabled = true;
        htmlButton.disabled = true;

        /** @type {String} */
        const str = await filePromise(htmlFile.files[0]);

        /** @type {Array} */
        const linhas = str.split("\n");
        /** @type {Array} */
        const colunas = linhas[0].trim().split("|");

        let dataObject = {
            "fromjs": []
        };

        let temp;
        let linha;

        for (let i = 1; i < linhas.length; i++) {
            temp = {};
            linha = linhas[i].trim().split("|");
            for (let j = 0; j < colunas.length; j++) {
                temp[colunas[j]] = linha[j];
            }
            dataObject["fromjs"].push(temp);
        }

        await sasjs.request("services/common/updatedata", dataObject).then((res) => {
            let responseJson;

            try {
                responseJson = res;
            } catch (e) {
                console.error(e);
            }

            if (responseJson && responseJson.status === 449) {
                updatedata();
            } else if (responseJson) {
                console.log("Sucesso");
            }
        });
    }

    document.querySelector("#tablebutton").addEventListener("click", updatedata);
});

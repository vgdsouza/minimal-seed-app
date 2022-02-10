/* window.onload para garantir que todo o HTML já foi carregado */
window.addEventListener("load", function () {
    /** @type {HTMLInputElement} */
    const tablefile = document.querySelector("#tablefile");
    /** @type {HTMLButtonElement} */
    const tablebutton = document.querySelector("#tablebutton");

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

        if (myfile) {
            await sasjs.uploadFile(
                'services/common/updatedata',
                [{ "file": myfile, "fileName": myfile.name }],
                {"table": "This is a test"}
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
});

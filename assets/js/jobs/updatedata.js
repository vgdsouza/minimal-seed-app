/* window.onload para garantir que todo o HTML já foi carregado */
window.addEventListener("load", function () {
    /** @type {HTMLSelectElement} */
    const tablebutton = document.querySelector("#tablebutton");

    tablebutton.addEventListener("click", updatedata);

    async function updatedata() {
        /** @type {HTMLInputElement} */
        const tablefile = document.querySelector("#tablefile");

        tablefile.disabled = true;
        tablebutton.disabled = true;

        /** @type {File} */
        const myfile = tablefile.files[0];

        if (myfile) {
            await sasjs.uploadFile('services/common/updatedata', [{ "file": myfile, "fileName": myfile.name }]);
        }
    }
});

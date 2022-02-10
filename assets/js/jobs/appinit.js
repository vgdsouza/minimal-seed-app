/* window.onload para garantir que todo o HTML já foi carregado */
window.addEventListener("load", function () {
    var sasjs = new SASjs.default({
        appLoc: "/Public/app/ICL",
        serverType: "SASVIYA",
        serverUrl: "",
        debug: true,
        loginMechanism: "Redirected"
    });

    /* verificamos se o usuário está logado, em caso positivo executamos o
    job appinit para criar o select com o nome de todas as listas cadastradas
    na tabela de controle */
    sasjs.checkSession().then((res) => {
        if (res.isLoggedIn) {
            /** @type {HTMLParagraphElement} */
            const currentUser = document.querySelector("#currentUser");

            currentUser.innerText = res.userName;

            appinit();
        }
    });

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
                createSelectListas(responseJson.listas);
            }
        });
    }

    function createSelectListas(lists) {
        /** @type {HTMLSelectElement} */
        const tableselect = document.querySelector("#tableselect");
        /** @type {HTMLInputElement} */
        const tablefile = document.querySelector("#tablefile");
        /** @type {HTMLDivElement} */
        const spinner = document.querySelector("#spinner");
        /** @type {HTMLDivElement} */
        const main = document.querySelector("#main");

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
});

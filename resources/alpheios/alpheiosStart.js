

document.addEventListener("DOMContentLoaded", function(event) {
      import ("resources/js/external/alpheios/alpheios-embedded.min.js").then(embedLib => {

        window.AlpheiosEmbed.importDependencies({ mode: 'custom', libs: { components: "resources/js/external/alpheios/alpheios-components.min.js"} }).then(Embedded => {
          new Embedded({clientId: 'https://betamasaheft.eu', enabledSelector: ".word" }).activate();
        }).catch(e => {
          console.error(`Import of an embedded library dependencies failed: ${e}`)
        })

      }).catch(e => {
        console.error(`Import of an embedded library failed: ${e}`)
      })
    });
    
  
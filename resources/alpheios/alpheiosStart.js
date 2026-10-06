

// import() and the components loader resolve against a URL, not the page's relative path, so a
// bare "resources/..." specifier is rejected. Derive both from this script's own location
// (resources/alpheios/) so it works under any mount path.
var alpheiosBase = document.currentScript.src;
var alpheiosLib = function (file) {
  return new URL("../js/external/alpheios/" + file, alpheiosBase).href;
};

document.addEventListener("DOMContentLoaded", function(event) {
      import (alpheiosLib("alpheios-embedded.min.js")).then(embedLib => {

        window.AlpheiosEmbed.importDependencies({ mode: 'custom', libs: { components: alpheiosLib("alpheios-components.min.js")} }).then(Embedded => {
          new Embedded({clientId: 'https://betamasaheft.eu', enabledSelector: ".word" }).activate();
        }).catch(e => {
          console.error(`Import of an embedded library dependencies failed: ${e}`)
        })

      }).catch(e => {
        console.error(`Import of an embedded library failed: ${e}`)
      })
    });
    
  
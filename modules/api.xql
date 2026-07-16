xquery version "3.1" encoding "UTF-8";

(:~
 : roaster OpenAPI router entry point. Routes requests according to
 : routes.json, resolving each operationId to a function in one of the
 : imported restview/module namespaces. Replaces the classic RESTXQ
 : (%rest:*) dispatch previously handled by controller.xql forwarding to
 : eXist's built-in RestXqServlet.
 :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace aka = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/aka" at "../modules/academics.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dts" at "../modules/dts.xqm";
import module namespace viewer = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/iiifviewer" at "../restviews/viewer.xqm";
import module namespace restItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/restItem" at "../restviews/items.xqm";
import module namespace PermRestItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/PermRestItem" at "../restviews/permanentItems.xqm";
import module namespace list = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/list" at "../restviews/list.xqm";
import module namespace litcomp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/litcomp" at "../restviews/litcompare.xqm";
import module namespace LitFlowRest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlowRest" at "../restviews/LitFlowRest.xqm";
import module namespace collatex = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/collatex" at "../restviews/collatex.xqm";
import module namespace comparems = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/comparems" at "../restviews/comparems.xqm";
import module namespace compare = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/compare" at "../restviews/compare.xqm";
import module namespace genderInfo = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/genderInfo" at "../restviews/genderInfo.xqm";
import module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lookID" at "../restviews/idlookup.xqm";
import module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listIds" at "../restviews/ids.xqm";
import module namespace user = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/user" at "../restviews/user.xqm";
import module namespace workmap = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/workmap" at "../restviews/workmap.xqm";

declare function local:lookup($name as xs:string) {
	function-lookup(xs:QName($name), 1)
};

roaster:route(("modules/routes.json"), local:lookup#1)

$(document).ready(function () {
//	var mineNumber = MINENUMBER;
//	var mineHasFound = MINEHASFOUND;
//	var rectTable = RECTTABLE;

	var refreshInterval = 0.5;
		token=0;

	var $temp = new Date();
	token = $temp.getTime(); // use for config which one it is

	window.onbeforeunload = function () {
		$.ajax({
			type: 'POST',
			url: '/ajax/',
			data: {id: token, willLeave: true},
			success: function (response) {
				;
			},
			async: false,
			dataType: 'text'
		});
		return "asdads";
	};

	(function ajaxFunc() {
		$.ajax({
			type: 'POST',
			url: '/ajax/',
			data: {mineHasFound: MINEHASFOUND, id: token},
			success: function (response) {
				console.log(response);
			},
			dataType: 'text'
		});
		setTimeout(ajaxFunc, 1000);
	})();
});
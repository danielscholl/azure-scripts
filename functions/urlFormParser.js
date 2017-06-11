// Copyright(c) 2017, cloudcodeit.com
module.exports = (context, data) => {
  const parsedForm = parseQuery(data.form);
  context.log(parsedForm);
  context.res = {
    body: parsedForm
  }
  context.done();
};

function parseQuery(input) {
  const arr = input.replace('+', ' ').substr(0).split('&');

  let output = {};
  for (let i = 0, len = arr.length; i < len; i++) {
    const item = arr[i].split('=');
    output[decodeURIComponent(item[0])] = decodeURIComponent(item[1] || '');
  }
  return output;
}

package com.cotton

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.ae.cotton.ui.theme.Purple200
import com.ae.cotton.ui.theme.Purple500
import com.ae.cotton.ui.theme.Purple700
import com.cotton.R

// https://www.devbitsandbytes.com/configuring-searchview-in-jetpack-compose/

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun SearchBar(
    searchText: String,
    placeholderText: String,
    onSearchTextChanged: (String) -> Unit = {},
    onClearClick: () -> Unit = {}
) {
    var showClearButton by remember { mutableStateOf(false) }
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusRequester = remember { FocusRequester() }

    TopAppBar(
        title = {
             Spacer(modifier = Modifier.width(0.dp))
        },
        navigationIcon = {
            Icon(
                imageVector = Icons.Filled.Search,
                modifier = Modifier,
                contentDescription = stringResource(id = R.string.icn_search_magnifier_icon_description)
            )
    }, actions = {
        OutlinedTextField(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 2.dp)
                .onFocusChanged { focusState ->
                    showClearButton = (focusState.isFocused)
                }
                .focusRequester(focusRequester),
            value = searchText,
            onValueChange = onSearchTextChanged,
            placeholder = {
                Text(
                    text = placeholderText,
                    color = Purple700)
            },
            colors = TextFieldDefaults.textFieldColors(
                focusedIndicatorColor = Purple200,
                unfocusedIndicatorColor = Purple200,
                backgroundColor = Purple200,
                cursorColor = LocalContentColor.current.copy(alpha = LocalContentAlpha.current)
            ),
            trailingIcon = {
                AnimatedVisibility(
                    visible = showClearButton,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    IconButton(onClick = {
                        keyboardController?.hide()
                        onClearClick()
                    }) {
                        Icon(
                            imageVector = Icons.Filled.Close,
                            contentDescription = stringResource(id = R.string.icn_search_clear_content_description)
                        )
                    }

                }
            },
            maxLines = 1,
            singleLine = true,
            keyboardOptions = KeyboardOptions.Default.copy(imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = {
                keyboardController?.hide()
            }),
        )


    })
    LaunchedEffect(Unit) {
        // Don't request focus to not have keyboard visible at app start
        // focusRequester.requestFocus()
    }
}